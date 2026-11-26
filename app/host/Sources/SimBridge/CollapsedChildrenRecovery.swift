// Adapted from sim-use (https://github.com/lycorp-jp/sim-use),
// Sources/iOSSimBackend/A11y/AccessibilityFetcher.swift at cd6caf9,
// Copyright 2026 LY Corporation, licensed under the Apache License 2.0
// (see LICENSE-sim-use). Changes:
// - Nodes are our JSON dictionaries (`role`, `label`, `frame`, `children`)
//   instead of idb's (`AXLabel`, `AXFrame`); the identity key formats the
//   frame itself rather than reading idb's `AXFrame` string.
// - The probe is synchronous, and a wall-clock deadline stops probing in
//   addition to the probe budget.
// - Logging and perf counters are dropped.
// - A root with no children at all is probed as a phase-1 container
//   whatever its role (sim-use's tree source never returns that shape).
// - A probe hit may carry children (see `Accessibility`); they are kept,
//   minus any element already seen, so a hit holding a tab bar brings its
//   tabs even when hit testing only ever answers with the holder.
// - A hit that is itself a container (a navigation bar's group, a tab group)
//   and came back without children is probed in turn instead of being
//   skipped as synthesized: the probe returns its element alone, so it is
//   empty however full it is on screen. Hits from the same level that lie
//   inside it are moved under it first, and their frames count as covered
//   there, so they are not probed twice. AXTabGroup and AXToolbar qualify
//   as containers alongside AXGroup.
// - A probe answer that adds nothing still steers the sampling. When the
//   parent, an ancestor or anything else covering the whole cell answers,
//   the cell is split into quadrants (under the same cap as a nil answer):
//   between controls the container answers, and the controls sit in the
//   gaps. When an element already seen, a neighbour or an existing child
//   answers, its frame counts as covered and the rest of the cell is
//   sampled, so every control in a row is reached whatever order the hits
//   come in.
// - A hit belongs to the probed region when it fits inside it to within
//   `overhang` points rather than 1 pt: a navigation bar's tab buttons and
//   heading stick out up to 1.7 pt above the bar's group.
// The quadtree, budgets, caps, thresholds and blind-zone maths are otherwise unchanged.

import CoreGraphics
import Foundation

public enum CollapsedChildrenRecovery {
    /// Resolves the accessibility element at a given screen point. Returning
    /// `nil` causes that sample point to be skipped.
    public typealias PointProbe = (CGPoint) -> [String: Any]?

    // Eligibility gate for phase 1.
    public static let minContainerWidth: Double = 100
    public static let minContainerHeight: Double = 30

    // Quadtree refinement parameters. Seed cells are rectangular (wider than
    // tall) to match the typical UI element aspect ratio: nav links,
    // headlines, cells and text rows are almost always landscape.
    public static let defaultSeedCellWidth: Double = 160
    public static let defaultSeedCellHeight: Double = 80
    public static let coverageTerminationRatio: Double = 0.95

    // Phase 2 thresholds. A gap rectangle between siblings must clear both
    // `minBlindZoneMinDim` on each side and `minBlindZoneArea` in total to
    // qualify: enough to host a plausible accessibility element rather than
    // inter-element padding.
    public static let minBlindZoneMinDim: Double = 60
    public static let minBlindZoneArea: Double = 10_000

    public static let defaultMaxProbes: Int = 300
    public static let defaultMinCellSize: Double = 14

    public static func recover(
        in root: [String: Any],
        probe: PointProbe,
        deadline: Date,
        maxProbes: Int = defaultMaxProbes,
        minCellSize: Double = defaultMinCellSize,
        seedCellWidth: Double = defaultSeedCellWidth,
        seedCellHeight: Double = defaultSeedCellHeight,
        scanBlindZones: Bool = true
    ) -> (tree: [String: Any], probes: Int) {
        let budget = ProbeBudget(maxProbes, deadline: deadline)
        let tuning = Tuning(
            minCellSize: max(1, minCellSize),
            seedCellWidth: max(1, seedCellWidth),
            seedCellHeight: max(1, seedCellHeight)
        )
        // Traversal-scoped identity set, pre-seeded with every original-tree
        // node so a probe hit that collides with a natively exposed element
        // is dropped, and shared across every runProbes call so sibling
        // AXGroup wrappers do not each synthesize their own copy of the same
        // on-screen element.
        let seen = SeenIdentitySet()
        prepopulateSeen(seen, from: root)
        let tree = walk(node: root, probe: probe, budget: budget, tuning: tuning, seen: seen, scanBlindZones: scanBlindZones, isRoot: true)
        return (tree, maxProbes - budget.remaining)
    }

    /// Identity key for cross-parent dedup of synthesized hits. Returns `nil`
    /// for nodes without a usable frame (missing or zero-sized).
    public static func identityKey(for node: [String: Any]) -> String? {
        guard let f = frameTuple(of: node), f.width > 0, f.height > 0 else { return nil }
        let frameStr = "{{\(f.x), \(f.y)}, {\(f.width), \(f.height)}}"
        let role = (node["role"] as? String) ?? ""
        let label = (node["label"] as? String) ?? ""
        return "\(frameStr)|\(role)|\(label)"
    }

    private static func prepopulateSeen(_ seen: SeenIdentitySet, from node: [String: Any]) {
        if let key = identityKey(for: node) {
            seen.insert(key)
        }
        if let kids = node["children"] as? [[String: Any]] {
            for child in kids {
                prepopulateSeen(seen, from: child)
            }
        }
    }

    public struct Tuning {
        public let minCellSize: Double
        public let seedCellWidth: Double
        public let seedCellHeight: Double
        public var minRemainderArea: Double { minCellSize * minCellSize }
        /// Cap on how many times a nil probe may trigger quadrant refinement
        /// within a single `runProbes` call. The uncapped cascade
        /// (1 → 4 → 16 → 64) multiplies budget pressure on genuinely empty
        /// space while rarely uncovering a hidden element.
        public let phase1NilRefineCap: Int = 16
        public let phase2NilRefineCap: Int = 6
    }

    /// `adopted` are hits found at the parent's level that lie inside this
    /// node: they become its children, and phase 1 treats their frames as
    /// already covered.
    private static func walk(
        node: [String: Any],
        adopted: [[String: Any]] = [],
        probe: PointProbe,
        budget: ProbeBudget,
        tuning: Tuning,
        seen: SeenIdentitySet,
        scanBlindZones: Bool,
        isRoot: Bool = false
    ) -> [String: Any] {
        var node = node

        let existing = (node["children"] as? [[String: Any]]) ?? []
        var children: [[String: Any]] = []
        children.reserveCapacity(existing.count + adopted.count)
        for child in existing {
            children.append(walk(node: child, probe: probe, budget: budget, tuning: tuning, seen: seen, scanBlindZones: scanBlindZones))
        }

        // Phase 1 — probe empty containers (and an empty root).
        var found = adopted
        if existing.isEmpty, shouldProbe(node) || (isRoot && rect(of: node) != nil) {
            found += runProbes(
                parent: node, seedRegions: nil, existingChildren: adopted,
                probe: probe, budget: budget, tuning: tuning, seen: seen
            )
        }
        for (probed, inside) in nest(found) {
            children.append(walk(node: probed, adopted: inside, probe: probe, budget: budget, tuning: tuning, seen: seen, scanBlindZones: scanBlindZones))
        }

        // Phase 2 — probe significant blind zones between siblings.
        if scanBlindZones,
           !children.isEmpty,
           let region = rect(of: node),
           region.width >= minContainerWidth,
           region.height >= minContainerHeight {
            let childFrames = children.compactMap { rect(of: $0) }
            let blindZones = computeBlindZones(in: region, coveredBy: childFrames)
                .filter { zone in
                    min(zone.width, zone.height) >= CGFloat(minBlindZoneMinDim)
                        && zone.width * zone.height >= CGFloat(minBlindZoneArea)
                }
            if !blindZones.isEmpty {
                let discovered = runProbes(
                    parent: node, seedRegions: blindZones, existingChildren: children,
                    probe: probe, budget: budget, tuning: tuning, seen: seen
                )
                for (probed, inside) in nest(discovered) {
                    children.append(walk(node: probed, adopted: inside, probe: probe, budget: budget, tuning: tuning, seen: seen, scanBlindZones: scanBlindZones))
                }
            }
        }

        node["children"] = children
        return node
    }

    /// Roles that hold other elements: the shapes AXPTranslator collapses.
    public static let containerRoles: Set<String> = ["AXGroup", "AXTabGroup", "AXToolbar"]

    /// Roles whose children a probe reads along with the hit: the
    /// containers, and headings, which in a navigation bar can hold its tab
    /// bar.
    public static let holderRoles: Set<String> = containerRoles.union(["AXHeading"])

    /// How far, in points, an element may stick out of the container it
    /// belongs to.
    public static let overhang: Double = 4

    public static func shouldProbe(_ node: [String: Any]) -> Bool {
        guard let role = node["role"] as? String, containerRoles.contains(role) else { return false }
        // Synthesized hits are probed too: a probe may return its element
        // without children, so a container hit is empty however full it is
        // on screen. `seen` stops a hit from being added twice, so nested
        // probing ends.
        guard let f = frameTuple(of: node),
              f.width >= minContainerWidth,
              f.height >= minContainerHeight else {
            return false
        }
        return true
    }

    /// Core quadtree orchestrator. Phase 1 passes `seedRegions == nil` and
    /// `existingChildren == []` so the entire parent frame is seeded. Phase 2
    /// passes the blind-zone rectangles and the parent's direct children so
    /// their frames pre-populate the covered set.
    private static func runProbes(
        parent: [String: Any],
        seedRegions: [CGRect]?,
        existingChildren: [[String: Any]],
        probe: PointProbe,
        budget: ProbeBudget,
        tuning: Tuning,
        seen: SeenIdentitySet
    ) -> [[String: Any]] {
        guard let region = rect(of: parent) else { return [] }
        let parentKey = identityKey(for: parent)
        let slack: CGFloat = 1.0
        let regionArea = region.width * region.height
        let coverageTarget = regionArea * CGFloat(coverageTerminationRatio)

        var queue = WorkQueue()
        let childFrames: [CGRect] = existingChildren.compactMap { rect(of: $0) }
        var covered: [CGRect] = childFrames
        var hits: [[String: Any]] = []
        var coveredArea: CGFloat = 0
        var nilRefineCount = 0

        // Seed cells, intersected with the region so cells never straddle
        // the container boundary.
        let cellW = CGFloat(tuning.seedCellWidth)
        let cellH = CGFloat(tuning.seedCellHeight)
        let regions = seedRegions ?? [region]
        for seed in regions {
            let clipped = seed.intersection(region)
            if clipped.isNull || clipped.isEmpty { continue }
            let cols = max(1, Int((clipped.width / cellW).rounded(.up)))
            let rows = max(1, Int((clipped.height / cellH).rounded(.up)))
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = clipped.minX + CGFloat(col) * cellW
                    let y = clipped.minY + CGFloat(row) * cellH
                    let w = min(cellW, clipped.maxX - x)
                    let h = min(cellH, clipped.maxY - y)
                    if w <= 0 || h <= 0 { continue }
                    queue.push(CGRect(x: x, y: y, width: w, height: h))
                }
            }
        }

        let touchTargetSlop: CGFloat = 2

        drain: while let cell = queue.pop(), budget.available {
            let centre = CGPoint(x: cell.midX, y: cell.midY)

            // Opportunistic remainder subdivide: everything the hit did not
            // occupy becomes a candidate for further sampling so thin
            // neighbours stay reachable through the refinement chain.
            func sampleRest(besides hitRect: CGRect) {
                for remainder in subtract(hitRect, from: cell)
                where remainder.width * remainder.height > CGFloat(tuning.minRemainderArea) {
                    queue.push(remainder)
                }
            }

            // A cell centred on something already found is not probed, but
            // the rest of it is still sampled: a strip left beside one tab
            // can run on into the next.
            if let known = covered.first(where: { $0.insetBy(dx: -touchTargetSlop, dy: -touchTargetSlop).contains(centre) }) {
                sampleRest(besides: known.insetBy(dx: -touchTargetSlop, dy: -touchTargetSlop))
                continue
            }

            budget.consume()

            // Nil-refine is capped per phase: phase 1 looser (small AXGroup
            // containers may hide a single tight element), phase 2 tighter
            // (the blind zone is usually either populated or really empty).
            // Answers that cover the whole cell without adding to it count
            // as nil: between controls the container answers.
            let cap = seedRegions == nil ? tuning.phase1NilRefineCap : tuning.phase2NilRefineCap
            func refine() {
                if nilRefineCount < cap, min(cell.width, cell.height) > CGFloat(tuning.minCellSize) {
                    for quadrant in splitQuadrants(cell) { queue.push(quadrant) }
                    nilRefineCount += 1
                }
            }

            guard let hit = probe(centre), let hitRect = rect(of: hit) else {
                refine()
                continue
            }

            let isParent = parentKey != nil
                && identityKey(for: hit).map({ $0.components(separatedBy: "|")[0] }) == parentKey!.components(separatedBy: "|")[0]
            let fits = rectContained(hitRect, in: region, slack: CGFloat(overhang))
            let overlap = hitRect.intersection(cell)
            if isParent || overlap.isNull || overlap.isEmpty || (!fits && hitRect.insetBy(dx: -slack, dy: -slack).contains(cell)) {
                // The parent, an ancestor, or an answer that misses the cell.
                refine()
                continue
            }

            // Nil key → zero/missing-frame hit: bypass identity dedup.
            let key = identityKey(for: hit)
            // A hit inside any existing direct-child frame (phase 2's
            // children, phase 1's adopted hits) is already represented by
            // that child or is found by probing it.
            let isNew = fits
                && !childFrames.contains(where: { rectContained(hitRect, in: $0, slack: slack) })
                && !(key.map(seen.contains) ?? false)
            guard isNew else {
                // A neighbour, or an element already found: the rest of the
                // cell may still hold something new.
                covered.append(hitRect)
                sampleRest(besides: hitRect)
                continue
            }
            if let key { seen.insert(key) }
            hits.append(claim(hit, seen: seen))
            covered.append(hitRect)

            let clipped = hitRect.intersection(region)
            if !clipped.isNull {
                coveredArea += clipped.width * clipped.height
                if coveredArea >= coverageTarget { break drain }
            }

            sampleRest(besides: hitRect)
        }
        return hits
    }

    // MARK: - Geometry helpers

    /// The hit, marked as synthesized, with any children it came with minus
    /// the elements already seen (whose own children take their place).
    /// Records what it keeps in `seen`.
    private static func claim(_ hit: [String: Any], seen: SeenIdentitySet) -> [String: Any] {
        var node = hit
        node["synthesized"] = true
        var children: [[String: Any]] = []
        for child in (hit["children"] as? [[String: Any]]) ?? [] {
            if let key = identityKey(for: child) {
                if seen.contains(key) {
                    children += (claim(child, seen: seen)["children"] as? [[String: Any]]) ?? []
                    continue
                }
                seen.insert(key)
            }
            children.append(claim(child, seen: seen))
        }
        node["children"] = children
        return node
    }

    /// Groups hits found at one level by where they sit: each goes under
    /// the smallest container hit (by `containerRoles`) that holds it to
    /// within `overhang`. Returns the outermost hits, in their original
    /// order, each with every hit inside it, however deep; walking the
    /// holder nests those further.
    private static func nest(_ hits: [[String: Any]]) -> [(node: [String: Any], inside: [[String: Any]])] {
        guard hits.count > 1 else { return hits.map { ($0, []) } }
        let rects = hits.map { rect(of: $0) }
        func area(_ i: Int) -> CGFloat { rects[i].map { $0.width * $0.height } ?? 0 }
        var holder = [Int?](repeating: nil, count: hits.count)
        for i in hits.indices {
            guard let r = rects[i], area(i) > 0 else { continue }
            for j in hits.indices where j != i {
                guard let h = rects[j], containerRoles.contains((hits[j]["role"] as? String) ?? ""),
                      area(j) > area(i), rectContained(r, in: h, slack: CGFloat(overhang)) else { continue }
                if holder[i].map({ area(j) < area($0) }) ?? true { holder[i] = j }
            }
        }
        // Holders are strictly larger, so each chain ends.
        func outermost(_ i: Int) -> Int { holder[i].map(outermost) ?? i }
        var inside: [Int: [[String: Any]]] = [:]
        for i in hits.indices where holder[i] != nil { inside[outermost(i), default: []].append(hits[i]) }
        return hits.indices.filter { holder[$0] == nil }.map { (hits[$0], inside[$0] ?? []) }
    }

    private static func rectContained(_ inner: CGRect, in outer: CGRect, slack: CGFloat) -> Bool {
        if inner.minX + slack < outer.minX { return false }
        if inner.maxX > outer.maxX + slack { return false }
        if inner.minY + slack < outer.minY { return false }
        if inner.maxY > outer.maxY + slack { return false }
        return true
    }

    private static func splitQuadrants(_ cell: CGRect) -> [CGRect] {
        let halfW = cell.width / 2
        let halfH = cell.height / 2
        return [
            CGRect(x: cell.minX, y: cell.minY, width: halfW, height: halfH),
            CGRect(x: cell.minX + halfW, y: cell.minY, width: halfW, height: halfH),
            CGRect(x: cell.minX, y: cell.minY + halfH, width: halfW, height: halfH),
            CGRect(x: cell.minX + halfW, y: cell.minY + halfH, width: halfW, height: halfH),
        ]
    }

    // Classic 4-strip rectangle subtraction: `cell` minus the portion of
    // `hit` that overlaps it.
    private static func subtract(_ hit: CGRect, from cell: CGRect) -> [CGRect] {
        let ix = cell.intersection(hit)
        if ix.isNull || ix.isEmpty { return [] }
        var strips: [CGRect] = []
        if ix.minY > cell.minY {
            strips.append(CGRect(x: cell.minX, y: cell.minY, width: cell.width, height: ix.minY - cell.minY))
        }
        if ix.maxY < cell.maxY {
            strips.append(CGRect(x: cell.minX, y: ix.maxY, width: cell.width, height: cell.maxY - ix.maxY))
        }
        if ix.minX > cell.minX {
            strips.append(CGRect(x: cell.minX, y: ix.minY, width: ix.minX - cell.minX, height: ix.height))
        }
        if ix.maxX < cell.maxX {
            strips.append(CGRect(x: ix.maxX, y: ix.minY, width: cell.maxX - ix.maxX, height: ix.height))
        }
        return strips
    }

    /// Horizontal-strip decomposition of `region \ ⋃ covers`, with vertically
    /// adjacent strips that share the same x-span merged into tall rectangles.
    public static func computeBlindZones(in region: CGRect, coveredBy covers: [CGRect]) -> [CGRect] {
        guard region.width > 0, region.height > 0 else { return [] }

        let clipped: [CGRect] = covers.compactMap { r in
            let ix = r.intersection(region)
            return (ix.isNull || ix.isEmpty) ? nil : ix
        }
        if clipped.isEmpty { return [region] }

        var ys: Set<CGFloat> = [region.minY, region.maxY]
        for r in clipped {
            ys.insert(r.minY)
            ys.insert(r.maxY)
        }
        let sortedYs = ys.sorted()

        var zones: [CGRect] = []
        for i in 0..<(sortedYs.count - 1) {
            let yTop = sortedYs[i]
            let yBot = sortedYs[i + 1]
            let stripHeight = yBot - yTop
            if stripHeight <= 0 { continue }

            var intervals: [(x0: CGFloat, x1: CGFloat)] = []
            for r in clipped where r.minY < yBot && r.maxY > yTop {
                intervals.append((r.minX, r.maxX))
            }
            intervals.sort { $0.x0 < $1.x0 }

            var merged: [(x0: CGFloat, x1: CGFloat)] = []
            for iv in intervals {
                if !merged.isEmpty, merged[merged.count - 1].x1 >= iv.x0 {
                    merged[merged.count - 1].x1 = max(merged[merged.count - 1].x1, iv.x1)
                } else {
                    merged.append(iv)
                }
            }

            var x = region.minX
            for iv in merged {
                if iv.x0 > x {
                    zones.append(CGRect(x: x, y: yTop, width: iv.x0 - x, height: stripHeight))
                }
                x = max(x, iv.x1)
            }
            if x < region.maxX {
                zones.append(CGRect(x: x, y: yTop, width: region.maxX - x, height: stripHeight))
            }
        }

        zones.sort { lhs, rhs in
            if lhs.minX != rhs.minX { return lhs.minX < rhs.minX }
            return lhs.minY < rhs.minY
        }
        var mergedZones: [CGRect] = []
        let tol: CGFloat = 0.001
        for z in zones {
            if let last = mergedZones.last,
               abs(last.minX - z.minX) < tol,
               abs(last.width - z.width) < tol,
               abs(last.maxY - z.minY) < tol {
                mergedZones[mergedZones.count - 1] = CGRect(x: last.minX, y: last.minY, width: last.width, height: last.height + z.height)
            } else {
                mergedZones.append(z)
            }
        }
        return mergedZones
    }

    private static func frameTuple(of node: [String: Any]) -> (x: Double, y: Double, width: Double, height: Double)? {
        guard let f = node["frame"] as? [String: Any] else { return nil }
        func readNumber(_ v: Any?) -> Double? {
            if let d = v as? Double { return d }
            if let n = v as? NSNumber { return n.doubleValue }
            return nil
        }
        guard let x = readNumber(f["x"]), let y = readNumber(f["y"]),
              let width = readNumber(f["width"]), let height = readNumber(f["height"]) else { return nil }
        return (x, y, width, height)
    }

    private static func rect(of node: [String: Any]) -> CGRect? {
        guard let f = frameTuple(of: node) else { return nil }
        return CGRect(x: f.x, y: f.y, width: f.width, height: f.height)
    }
}

/// Shared probe counter threaded through every probe in one `recover` call,
/// so phase 1 and phase 2 drain the same budget. Also stops at `deadline`.
private final class ProbeBudget {
    private(set) var remaining: Int
    private let deadline: Date

    init(_ budget: Int, deadline: Date) {
        remaining = max(0, budget)
        self.deadline = deadline
    }

    var available: Bool { remaining > 0 && Date() < deadline }

    func consume() {
        if remaining > 0 { remaining -= 1 }
    }
}

/// Traversal-scoped dedup for synthesized probe hits.
private final class SeenIdentitySet {
    private var keys: Set<String> = []
    func insert(_ key: String) { keys.insert(key) }
    func contains(_ key: String) -> Bool { keys.contains(key) }
}

/// Max-heap by rectangle area (sorted array; popping takes the largest). On
/// ties the oldest insertion pops first.
private struct WorkQueue {
    private var items: [(rect: CGRect, area: CGFloat)] = []

    mutating func push(_ rect: CGRect) {
        let area = rect.width * rect.height
        if area <= 0 { return }
        let idx = items.firstIndex(where: { $0.area >= area }) ?? items.endIndex
        items.insert((rect, area), at: idx)
    }

    mutating func pop() -> CGRect? {
        items.popLast()?.rect
    }
}
