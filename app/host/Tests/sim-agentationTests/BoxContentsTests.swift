import CoreGraphics
import Foundation
import SimBridge
import Testing
@testable import sim_agentation

/// An iPhone 18 Pro screen (402×874 pt) as the simulator's accessibility
/// tree has it in full: a navigation bar group holding Settings, a heading
/// with six mode tabs in a tab group, and Debug, above a touchpad, a scroll
/// strip and three buttons. The tabs and the heading stick out above the
/// bar's group by up to 1.7 pt.
enum Screen {
    static func n(_ role: String, _ label: String?, _ id: String?, _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ children: [[String: Any]] = []) -> [String: Any] {
        [
            "role": role,
            "label": label ?? NSNull(),
            "identifier": id ?? NSNull(),
            "frame": ["x": x, "y": y, "width": w, "height": h],
            "hidden": false,
            "children": children,
        ]
    }

    // Computed, since [String: Any] isn't Sendable.
    static var full: [String: Any] {
        n("AXApplication", "Peri Keys", nil, 0, 0, 402, 874, [
            n("AXGroup", nil, nil, 0, 0, 402, 874, [
                n("AXGroup", nil, nil, 0, 0, 402, 874, [
                    n("AXGroup", nil, nil, 0, 0, 402, 874, [
                        n("AXGroup", nil, nil, 0, 0, 402, 874, [
                            n("AXGroup", nil, nil, 0, 0, 402, 874, [
                                n("AXGroup", nil, nil, 0, 0, 402, 874, [
                                    n("AXGroup", nil, "Peri", 0, 62, 402, 54, [
                                        n("AXButton", "Settings", nil, 20, 66, 36, 36),
                                        n("AXHeading", "Peri", nil, 72, 60 + 1.0 / 3, 258, 47 + 1.0 / 3, [
                                            n("AXGroup", nil, nil, 72, 60 + 1.0 / 3, 258, 47 + 1.0 / 3, [
                                                n("AXTabGroup", nil, nil, 60, 60 + 2.0 / 3, 282, 47, [
                                                    n("AXRadioButton", "Touchpad", "rectangle.and.hand.point.up.left", 60, 60 + 2.0 / 3, 47, 48, [
                                                        n("AXImage", "Rectangle with a hand pointing up-left", "rectangle.and.hand.point.up.left", 71 + 2.0 / 3, 73 + 2.0 / 3, 24, 22),
                                                    ]),
                                                    n("AXRadioButton", "Keyboard", "keyboard", 107, 60 + 2.0 / 3, 47, 48, [
                                                        n("AXImage", "Keyboard", "keyboard", 118, 76 + 2.0 / 3, 25, 16),
                                                    ]),
                                                    n("AXRadioButton", "Media", "playpause", 154, 60 + 2.0 / 3, 47, 48, [
                                                        n("AXImage", "Play/Pause", "playpause", 165, 77, 25 + 1.0 / 3, 15 + 2.0 / 3),
                                                    ]),
                                                    n("AXRadioButton", "Air Pointer", "cursorarrow.motionlines", 201, 60 + 2.0 / 3, 47, 48, [
                                                        n("AXImage", "Pointer arrow with motion lines", "pointer.arrow.motionlines", 214, 73 + 1.0 / 3, 21, 23),
                                                    ]),
                                                    n("AXRadioButton", "Game Controller", "gamecontroller", 248, 60 + 2.0 / 3, 47, 48, [
                                                        n("AXImage", "Game controller", "gamecontroller", 257 + 2.0 / 3, 75 + 2.0 / 3, 28, 18),
                                                    ]),
                                                    n("AXRadioButton", "Presenter", "videoprojector", 295, 60 + 2.0 / 3, 47, 48, [
                                                        n("AXImage", "Video projector", "videoprojector", 304, 77 + 2.0 / 3, 29, 14 + 1.0 / 3),
                                                    ]),
                                                ]),
                                            ]),
                                        ]),
                                        n("AXButton", "Debug", nil, 346, 66, 36, 36),
                                    ]),
                                    n("AXGroup", nil, nil, 0, 0, 402, 874, [
                                        n("AXGroup", nil, nil, 0, 0, 402, 874, [
                                            n("AXGroup", nil, nil, 0, 0, 402, 874, [
                                                n("AXGroup", nil, nil, 0, 0, 402, 874, [
                                                    n("AXPopUpButton", "Host: No host", nil, 16, 116, 91 + 2.0 / 3, 21 + 1.0 / 3, [
                                                        n("AXButton", nil, nil, 16, 116, 91 + 2.0 / 3, 21 + 1.0 / 3, [
                                                            n("AXStaticText", "Host: No host", nil, 18, 116, 89 + 2.0 / 3, 20 + 1.0 / 3),
                                                            n("AXImage", "Host: No host", "desktopcomputer.trianglebadge.exclamationmark", 18, 118, 25 + 1.0 / 3, 18),
                                                        ]),
                                                    ]),
                                                    n("AXPopUpButton", "Interfaces", "interfacesMenu", 282 + 1.0 / 3, 116 + 2.0 / 3, 103 + 2.0 / 3, 20 + 1.0 / 3, [
                                                        n("AXButton", nil, nil, 282 + 1.0 / 3, 116 + 2.0 / 3, 103 + 2.0 / 3, 20 + 1.0 / 3, [
                                                            n("AXImage", "Grid View", "square.grid.2x2", 284 + 1.0 / 3, 119 + 1.0 / 3, 15 + 1.0 / 3, 15 + 1.0 / 3),
                                                            n("AXStaticText", "Interfaces", nil, 284 + 1.0 / 3, 116 + 2.0 / 3, 101 + 2.0 / 3, 20 + 1.0 / 3),
                                                        ]),
                                                    ]),
                                                    n("AXStaticText", "This device can't act as a Bluetooth keyboard.", nil, 17 + 2.0 / 3, 159 + 2.0 / 3, 360, 19 + 1.0 / 3),
                                                    n("AXImage", "Warning", "exclamationmark.triangle", 17 + 2.0 / 3, 161 + 2.0 / 3, 16 + 2.0 / 3, 15),
                                                    n("AXGenericElement", "Touchpad", nil, 16, 189, 316, 581 + 1.0 / 3),
                                                    n("AXImage", "Scroll", "arrow.up.and.down", 340, 188 + 2.0 / 3, 46, 581 + 2.0 / 3),
                                                    n("AXSlider", "Scroll", nil, 340, 188 + 2.0 / 3, 46, 581 + 2.0 / 3),
                                                    n("AXStaticText", "Tap to click, two-finger tap to right-click, two fingers to scroll, tap then hold to drag.", nil, 32, 693, 257 + 1.0 / 3, 61 + 1.0 / 3),
                                                    n("AXButton", "Left click", nil, 16, 778 + 1.0 / 3, 127, 45 + 2.0 / 3, [
                                                        n("AXStaticText", "Click", nil, 16, 778 + 1.0 / 3, 127, 45 + 2.0 / 3),
                                                        n("AXImage", "Cursor Arrow With A Click Indicator", "cursorarrow.click", 48 + 1.0 / 3, 792 + 2.0 / 3, 17, 17 + 1.0 / 3),
                                                    ]),
                                                    n("AXButton", "Drag Lock", "lock", 151, 778 + 1.0 / 3, 100, 45 + 2.0 / 3),
                                                    n("AXButton", "Right Click", "contextualmenu.and.cursorarrow", 259, 778 + 1.0 / 3, 127, 45 + 2.0 / 3),
                                                ]),
                                            ]),
                                        ]),
                                    ]),
                                    n("AXGroup", "Toolbar", "Toolbar", 0, 0, 402, 874, [
                                        n("AXGroup", nil, nil, 0, 0, 402, 874),
                                    ]),
                                ]),
                                n("AXGroup", nil, nil, 0, 62, 402, 778),
                                n("AXGroup", nil, nil, 0, 62, 402, 778),
                            ]),
                        ]),
                    ]),
                ]),
            ]),
        ])
    }

    static let tabs = ["Touchpad", "Keyboard", "Media", "Air Pointer", "Game Controller", "Presenter"]
    /// Every control in the bar, by label.
    static let bar = ["Settings"] + tabs + ["Debug"]
    static let barBox = CGRect(x: 0, y: 60, width: 402, height: 57)

    /// The shapes the tree can arrive in before probing.
    enum Root: CaseIterable {
        /// The application element and nothing under it: the whole screen is probed.
        case empty
        /// The application element over the screen's leaves below the bar:
        /// the bar is a blind zone.
        case leaves
    }

    static func root(_ shape: Root) -> [String: Any] {
        var app = full
        switch shape {
        case .empty: app["children"] = [[String: Any]]()
        case .leaves:
            app["children"] = flatten(full).filter {
                children($0).isEmpty && frame($0).minY >= 115 && frame($0).width < 400
            }.map { leaf($0) }
        }
        return app
    }

    /// What objectAtPoint may answer with. Each answers with the topmost
    /// element under the point and skips unnamed groups, the toolbar group
    /// and the application.
    enum Answer: CaseIterable {
        /// The deepest element: a tab's icon over the icon, the tab around it.
        case deepest
        /// A control for every point inside it, icon included.
        case control
        /// The bar's group for every point in it outside Settings and Debug.
        case group
        /// The heading for every point in it.
        case heading
        /// The tab group for every point in it.
        case tabGroup
    }

    static let controlRoles: Set<String> = ["AXButton", "AXRadioButton", "AXCheckBox", "AXPopUpButton", "AXSlider", "AXGenericElement"]

    static func hit(_ n: [String: Any], _ p: CGPoint, _ answer: Answer) -> [String: Any]? {
        guard frame(n).contains(p) else { return nil }
        let r = role(n)
        if answer != .deepest && controlRoles.contains(r) { return n }
        if answer == .heading && r == "AXHeading" { return n }
        if answer == .tabGroup && r == "AXTabGroup" { return n }
        if answer == .group && name(n) == "Peri" && r == "AXGroup" {
            return children(n).first { role($0) == "AXButton" && frame($0).contains(p) } ?? n
        }
        for c in children(n).reversed() {
            if let h = hit(c, p, answer) { return h }
        }
        if (r == "AXGroup" && name(n).isEmpty) || name(n) == "Toolbar" || r == "AXApplication" { return nil }
        return n
    }

    /// A probe answering as `answer` would. With `children`, a hit that
    /// holds others comes with its subtree, as `Accessibility` reads it;
    /// otherwise every hit comes alone.
    static func probe(_ answer: Answer, children: Bool = false) -> CollapsedChildrenRecovery.PointProbe {
        { p in
            guard let h = hit(full, p, answer) else { return nil }
            return children && CollapsedChildrenRecovery.holderRoles.contains(role(h)) ? h : leaf(h)
        }
    }

    static func leaf(_ n: [String: Any]) -> [String: Any] {
        var n = n
        n["children"] = [[String: Any]]()
        return n
    }

    static func flatten(_ n: [String: Any]) -> [[String: Any]] { [n] + children(n).flatMap(flatten) }
    static func children(_ n: [String: Any]) -> [[String: Any]] { (n["children"] as? [[String: Any]]) ?? [] }
    static func role(_ n: [String: Any]) -> String { (n["role"] as? String) ?? "" }
    static func name(_ n: [String: Any]) -> String { (n["label"] as? String) ?? (n["identifier"] as? String) ?? "" }
    static func frame(_ n: [String: Any]) -> CGRect {
        let f = n["frame"] as! [String: Double]
        return CGRect(x: f["x"]!, y: f["y"]!, width: f["width"]!, height: f["height"]!)
    }
}

private func json(_ tree: [String: Any]) throws -> JSONObject {
    try #require(JSON.parse(JSONSerialization.data(withJSONObject: tree)).objectValue)
}

/// Controls (buttons and tabs) a box over the bar holds, by label.
private func controlsInBar(_ tree: [String: Any]) throws -> [String] {
    let box = JSON.object(JSONObject([
        "x": .number(Screen.barBox.minX), "y": .number(Screen.barBox.minY),
        "width": .number(Screen.barBox.width), "height": .number(Screen.barBox.height),
    ]))
    return AX.nodesInRect(try json(tree), box)
        .filter { ["AXButton", "AXRadioButton"].contains($0.node["role"]?.stringValue ?? "") }
        .compactMap { $0.node["label"]?.stringValue }
}

private func recover(_ root: Screen.Root, _ probe: @escaping CollapsedChildrenRecovery.PointProbe) -> (tree: [String: Any], probes: Int) {
    CollapsedChildrenRecovery.recover(in: Screen.root(root), probe: probe, deadline: .distantFuture)
}

private func duplicates(_ tree: [String: Any]) -> [String] {
    var counts: [String: Int] = [:]
    for n in Screen.flatten(tree) { if let k = CollapsedChildrenRecovery.identityKey(for: n) { counts[k, default: 0] += 1 } }
    return counts.filter { $0.value > 1 }.map(\.key).sorted()
}

@Suite struct CollapsedChildrenRecoveryTests {
    /// The probe names every control in the bar somewhere; sampling has to
    /// reach each, whatever order the hits come in.
    @Test(arguments: [Screen.Answer.deepest, .control], Screen.Root.allCases)
    func everyBarControlAProbeNamesIsFound(answer: Screen.Answer, root: Screen.Root) throws {
        let (tree, probes) = recover(root, Screen.probe(answer))
        #expect(try controlsInBar(tree).sorted() == Screen.bar.sorted())
        #expect(duplicates(tree).isEmpty)
        #expect(probes <= CollapsedChildrenRecovery.defaultMaxProbes)
    }

    /// When hit testing answers with the holder for every point in it, its
    /// children are the only way to the tabs.
    @Test(arguments: Screen.Answer.allCases, Screen.Root.allCases)
    func aHolderHitBringsItsControls(answer: Screen.Answer, root: Screen.Root) throws {
        let (tree, _) = recover(root, Screen.probe(answer, children: true))
        #expect(try controlsInBar(tree).sorted() == Screen.bar.sorted())
        #expect(duplicates(tree).isEmpty)
    }

    /// The bar's group answers between and over the tabs: Settings and
    /// Debug still turn up by looking closer.
    @Test(arguments: Screen.Root.allCases)
    func controlsBesideAnAnsweringGroupAreFound(root: Screen.Root) throws {
        let (tree, _) = recover(root, Screen.probe(.group))
        let found = try controlsInBar(tree)
        #expect(found.contains("Settings") && found.contains("Debug"), "\(found)")
        #expect(duplicates(tree).isEmpty)
    }

    /// Hits that lie inside a container hit go under it.
    @Test func controlsFoundBesideTheBarGoUnderIt() {
        let (tree, _) = recover(.empty, Screen.probe(.control))
        let bars = Screen.flatten(tree).filter { Screen.name($0) == "Peri" && Screen.role($0) == "AXGroup" }
        #expect(bars.count == 1)
        let held = bars.first.map { Screen.flatten($0).map(Screen.name) } ?? []
        for name in Screen.bar { #expect(held.contains(name), "\(name) in \(held)") }
    }

    @Test func aProbeThatOnlyEverHitsTheContainerEnds() {
        let group = Screen.leaf(Screen.flatten(Screen.full).first { Screen.name($0) == "Peri" && Screen.role($0) == "AXGroup" }!)
        let (tree, probes) = recover(.empty) { Screen.frame(group).contains($0) ? group : nil }
        let groups = Screen.children(tree).filter { Screen.name($0) == "Peri" }
        #expect(groups.count == 1)
        #expect(groups.first.map(Screen.children)?.isEmpty == true)
        #expect(probes <= CollapsedChildrenRecovery.defaultMaxProbes)
    }

    /// An element centred in the bar but reaching 6 pt below it is a
    /// neighbour, not one of the bar's.
    @Test func aNeighbourReachingOutOfTheContainerStaysOut() {
        let bar = Screen.n("AXGroup", nil, "Bar", 0, 62, 402, 54)
        let sheet = Screen.n("AXButton", "Sheet", nil, 100, 70, 200, 52)
        let root = Screen.n("AXApplication", "App", nil, 0, 0, 402, 874, [bar])
        let (tree, _) = CollapsedChildrenRecovery.recover(in: root, probe: { p in
            Screen.frame(sheet).contains(p) ? sheet : nil
        }, deadline: .distantFuture)
        let inBar = Screen.flatten(Screen.children(tree)[0]).map(Screen.name)
        #expect(!inBar.contains("Sheet"))
    }
}

@Suite struct FormatInsideTests {
    private func summary(_ n: [String: Any]) -> JSON {
        let f = Screen.frame(n)
        func r(_ v: CGFloat) -> JSON { .number((Double(v) * 10).rounded() / 10) }
        func s(_ key: String) -> JSON { (n[key] as? String).map(JSON.string) ?? .null }
        return .object(JSONObject([
            "role": s("role"), "label": s("label"), "identifier": s("identifier"), "value": .null, "title": .null,
            "frame": .object(JSONObject(["x": r(f.minX), "y": r(f.minY), "width": r(f.width), "height": r(f.height)])),
        ]))
    }

    /// What the server stores for a box: the full tree's nodes in it, smallest first, at most 20.
    private func inside(_ r: CGRect) throws -> [JSON] {
        let rect = JSON.object(JSONObject(["x": .number(r.minX), "y": .number(r.minY), "width": .number(r.width), "height": .number(r.height)]))
        return AX.nodesInRect(try json(Screen.full), rect).prefix(20).map { AX.summarize($0.node) }
    }

    private func annotation(kind: String, rect r: CGRect, target: JSON = .null, path: [String] = [], inside: [JSON]) -> JSONObject {
        JSONObject([
            "id": .string("a1"), "status": .string("pending"), "comment": .string("note"), "kind": .string(kind),
            "device": .object(JSONObject(["udid": .string("U"), "name": .string("iPhone"), "runtime": .null])),
            "rect": .object(JSONObject(["x": .number(r.minX), "y": .number(r.minY), "width": .number(r.width), "height": .number(r.height)])),
            "label": .string("Area"), "target": target, "within": .null, "targetPath": .array(path.map(JSON.string)),
            "parts": .array([]), "inside": .array(inside),
            "screen": .object(JSONObject(["app": .null, "headings": .array([])])), "app": .null,
            "source": .array([]), "views": .array([]), "controller": .null,
            "images": .object(JSONObject(["full": .string("f.jpg"), "crop": .string("c.jpg")])),
            "replies": .array([]), "resolution": .null,
        ])
    }

    private func node(_ label: String, _ role: String) -> [String: Any] {
        Screen.flatten(Screen.full).first { ($0["label"] as? String) == label && Screen.role($0) == role }!
    }

    private func insideLines(_ note: String) -> [String] {
        note.components(separatedBy: "\n").drop { $0 != "- **Inside the box**:" }.dropFirst().prefix { $0.hasPrefix("  - ") }.map { String($0) }
    }

    @Test func aBoxOverTheBarListsEveryControl() throws {
        let note = Format.toMarkdown(annotation(kind: "area", rect: Screen.barBox, inside: try inside(Screen.barBox)))
        let lines = insideLines(note)
        for name in Screen.bar { #expect(lines.contains { $0.contains("\"\(name)\"") }, "\(name) in \(note)") }
        // Each tab's icon is on the tab's line, symbol name and all.
        #expect(!lines.contains { $0.hasPrefix("  - Image") })
        #expect(lines.contains { $0.hasPrefix("  - RadioButton \"Presenter\" id=videoprojector") && $0.contains("showing Image \"Video projector\" id=videoprojector") })
        #expect(lines.count <= 13)
    }

    @Test func aClickOnTheBarListsEveryControl() throws {
        let bar = summary(Screen.flatten(Screen.full).first { Screen.name($0) == "Peri" && Screen.role($0) == "AXGroup" }!)
        let rect = CGRect(x: 0, y: 62, width: 402, height: 54)
        let note = Format.toMarkdown(annotation(kind: "element", rect: rect, target: bar, path: ["Group \"Peri\""], inside: try inside(rect)))
        #expect(note.contains("- **Element**: Group id=Peri at (0, 62) 402×54pt"))
        for name in Screen.bar { #expect(insideLines(note).contains { $0.contains("\"\(name)\"") }, "\(name) in \(note)") }
    }

    /// A list that fits is as stored: every image keeps its own line.
    @Test func aSinglePickListsWhatItHoldsAsStored() throws {
        let click = node("Left click", "AXButton")
        let rect = Screen.frame(click)
        let note = Format.toMarkdown(annotation(
            kind: "element", rect: rect, target: summary(click), path: ["Group", "Button \"Left click\""], inside: try inside(rect)
        ))
        #expect(note.contains("- **Element**: Button \"Left click\" at (16, 778) 127×46pt"))
        #expect(insideLines(note) == [
            "  - Image \"Cursor Arrow With A Click Indicator\" id=cursorarrow.click at (48, 793) 17×17pt",
            "  - Button \"Left click\" at (16, 778) 127×46pt",
            "  - StaticText \"Click\" at (16, 778) 127×46pt",
        ])
        #expect(note.contains("- **Search the source for**: `Left click`, `cursorarrow.click`, `Cursor Arrow With A Click Indicator`, `Click`"))
    }

    /// Search terms come from everything stored, icons included.
    @Test func aBoxStillOffersIconSymbolsToSearchFor() throws {
        let rect = CGRect(x: 10, y: 770, width: 385, height: 60)
        let note = Format.toMarkdown(annotation(kind: "area", rect: rect, inside: try inside(rect)))
        for term in ["cursorarrow.click", "Cursor Arrow With A Click Indicator", "Click"] { #expect(note.contains("`\(term)`"), "\(term) in \(note)") }
    }

    @Test func aLongListSaysHowManyAreLeftOut() {
        let buttons = (0..<15).map { summary(Screen.n("AXButton", "B\($0)", nil, Double($0) * 20, 70, 18, 18)) }
        let note = Format.toMarkdown(annotation(kind: "area", rect: Screen.barBox, inside: buttons))
        #expect(note.contains("\"B11\""))
        #expect(!note.contains("\"B12\""))
        #expect(note.contains("  - and 3 more"))
    }
}
