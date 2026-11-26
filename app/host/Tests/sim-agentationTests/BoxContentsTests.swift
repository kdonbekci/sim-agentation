import CoreGraphics
import Foundation
import SimBridge
import Testing
@testable import sim_agentation

/// The top bar of an iPhone 18 Pro (402×874 pt) as the simulator's
/// accessibility tree has it: a group holding Settings, a heading with six
/// mode tabs, and Debug. The tabs stick out 1.3 pt above the group.
private enum Bar {
    static func node(_ role: String, _ label: String?, _ id: String?, _ r: CGRect, _ children: [[String: Any]] = []) -> [String: Any] {
        [
            "role": role,
            "label": label ?? NSNull(),
            "identifier": id ?? NSNull(),
            "frame": ["x": Double(r.minX), "y": Double(r.minY), "width": Double(r.width), "height": Double(r.height)],
            "hidden": false,
            "children": children,
        ]
    }

    static let tabNames = ["Touchpad", "Keyboard", "Media", "Air Pointer", "Game Controller", "Presenter"]
    // Computed, since [String: Any] isn't Sendable.
    static var tabs: [[String: Any]] {
        tabNames.enumerated().map { i, name in
            node("AXRadioButton", name, nil, CGRect(x: 60 + 47 * Double(i), y: 60 + 2.0 / 3, width: 47, height: 48))
        }
    }
    static var settings: [String: Any] { node("AXButton", "Settings", nil, CGRect(x: 20, y: 66, width: 36, height: 36)) }
    static var debug: [String: Any] { node("AXButton", "Debug", nil, CGRect(x: 346, y: 66, width: 36, height: 36)) }
    static var group: [String: Any] { node("AXGroup", nil, "Peri", CGRect(x: 0, y: 62, width: 402, height: 54), [
        settings,
        node("AXHeading", "Peri", nil, CGRect(x: 72, y: 60 + 1.0 / 3, width: 258, height: 47 + 1.0 / 3), [
            node("AXTabGroup", nil, nil, CGRect(x: 60, y: 60 + 2.0 / 3, width: 282, height: 47), tabs),
        ]),
        debug,
    ]) }
    static let screen = CGRect(x: 0, y: 0, width: 402, height: 874)
    /// The application element with no children: the shape that leaves the
    /// whole screen to probing.
    static var emptyRoot: [String: Any] { node("AXApplication", "Peri Keys", nil, screen) }

    /// Answers like objectAtPoint: the element under the point, without its
    /// children. Controls take the hit; between them, the bar's group does.
    static func probe(_ p: CGPoint) -> [String: Any]? {
        for n in [settings, debug] + tabs where frame(n).contains(p) { return leaf(n) }
        return frame(group).contains(p) ? leaf(group) : nil
    }

    static func leaf(_ n: [String: Any]) -> [String: Any] {
        var n = n
        n["children"] = [[String: Any]]()
        return n
    }

    static func frame(_ n: [String: Any]) -> CGRect {
        let f = n["frame"] as! [String: Double]
        return CGRect(x: f["x"]!, y: f["y"]!, width: f["width"]!, height: f["height"]!)
    }
}

private func labels(_ n: [String: Any]) -> [String] {
    let own = (n["label"] as? String).map { [$0] } ?? []
    return own + ((n["children"] as? [[String: Any]]) ?? []).flatMap(labels)
}

private func json(_ tree: [String: Any]) throws -> JSONObject {
    try #require(JSON.parse(JSONSerialization.data(withJSONObject: tree)).objectValue)
}

@Suite struct CollapsedChildrenRecoveryTests {
    @Test func everyControlInABarHitAsAGroupIsFound() {
        let (tree, _) = CollapsedChildrenRecovery.recover(in: Bar.emptyRoot, probe: Bar.probe, deadline: .distantFuture)
        let found = labels(tree)
        for name in ["Settings", "Debug"] + Bar.tabNames {
            #expect(found.filter { $0 == name }.count == 1, "\(name) in \(found)")
        }
    }

    @Test func aProbeThatOnlyEverHitsTheContainerEnds() {
        let (tree, probes) = CollapsedChildrenRecovery.recover(
            in: Bar.emptyRoot, probe: { Bar.frame(Bar.group).contains($0) ? Bar.leaf(Bar.group) : nil }, deadline: .distantFuture
        )
        let groups = ((tree["children"] as? [[String: Any]]) ?? []).filter { ($0["identifier"] as? String) == "Peri" }
        #expect(groups.count == 1)
        #expect(((groups.first?["children"] as? [[String: Any]]) ?? []).isEmpty)
        #expect(probes <= CollapsedChildrenRecovery.defaultMaxProbes)
    }

    @Test func aBoxOverTheBarHoldsEveryControl() throws {
        let (recovered, _) = CollapsedChildrenRecovery.recover(in: Bar.emptyRoot, probe: Bar.probe, deadline: .distantFuture)
        let tree = try json(recovered)
        let box = JSON.object(JSONObject(["x": .number(0), "y": .number(60), "width": .number(402), "height": .number(57)]))
        let inside = AX.nodesInRect(tree, box).map { AX.describe($0.node) }
        for name in ["Settings", "Debug"] + Bar.tabNames {
            #expect(inside.contains { $0.hasSuffix("\"\(name)\"") }, "\(name) in \(inside)")
        }
    }
}

@Suite struct FormatInsideTests {
    private func summary(_ role: String, _ label: String, _ x: Double, _ y: Double, _ w: Double, _ h: Double) -> JSON {
        .object(JSONObject([
            "role": .string(role), "label": .string(label), "identifier": .null, "value": .null, "title": .null,
            "frame": .object(JSONObject(["x": .number(x), "y": .number(y), "width": .number(w), "height": .number(h)])),
        ]))
    }

    private func annotation(kind: String, target: JSON = .null, path: [String] = [], inside: [JSON]) -> JSONObject {
        JSONObject([
            "id": .string("a1"), "status": .string("pending"), "comment": .string("the bar"), "kind": .string(kind),
            "device": .object(JSONObject(["udid": .string("U"), "name": .string("iPhone"), "runtime": .null])),
            "rect": .object(JSONObject(["x": .number(0), "y": .number(60), "width": .number(402), "height": .number(57)])),
            "label": .string("Area"), "target": target, "within": .null, "targetPath": .array(path.map(JSON.string)),
            "parts": .array([]), "inside": .array(inside),
            "screen": .object(JSONObject(["app": .null, "headings": .array([])])), "app": .null,
            "source": .array([]), "views": .array([]), "controller": .null,
            "images": .object(JSONObject(["full": .string("f.jpg"), "crop": .string("c.jpg")])),
            "replies": .array([]), "resolution": .null,
        ])
    }

    @Test func iconsInsideLabelledControlsAreLeftOut() {
        // Smallest first, as AX.nodesInRect stores them: the six icons come first.
        let icons = (0..<6).map { summary("AXImage", "Icon \($0)", 72 + 47 * Double($0), 74, 24, 22) }
        let tabs = Bar.tabNames.enumerated().map { summary("AXRadioButton", $1, 60 + 47 * Double($0), 60.7, 47, 48) }
        let note = Format.toMarkdown(annotation(kind: "area", inside: icons + [
            summary("AXButton", "Settings", 20, 66, 36, 36), summary("AXButton", "Debug", 346, 66, 36, 36),
        ] + tabs + [summary("AXStaticText", "Peri", 140, 70, 120, 20)]))
        #expect(!note.contains("Image"))
        for name in ["Settings", "Debug"] + Bar.tabNames { #expect(note.contains("\"\(name)\""), "\(name)") }
        // Text that isn't inside a listed control stays.
        #expect(note.contains("StaticText \"Peri\""))
        #expect(!note.contains("more"))
    }

    @Test func aLongListSaysHowManyAreLeftOut() {
        let buttons = (0..<15).map { summary("AXButton", "B\($0)", Double($0) * 20, 70, 18, 18) }
        let note = Format.toMarkdown(annotation(kind: "area", inside: buttons))
        #expect(note.contains("\"B11\""))
        #expect(!note.contains("\"B12\""))
        #expect(note.contains("  - and 3 more"))
    }

    @Test func aSinglePickStillNamesItsElementAndPath() {
        let debug = summary("AXButton", "Debug", 346, 66, 36, 36)
        let note = Format.toMarkdown(annotation(
            kind: "element", target: debug, path: ["Group \"Peri\"", "Button \"Debug\""],
            inside: [summary("AXImage", "Ladybug", 352, 72, 24, 24), debug]
        ))
        #expect(note.contains("- **Element**: Button \"Debug\" at (346, 66) 36×36pt"))
        #expect(note.contains("- **Path**: Group \"Peri\" › Button \"Debug\""))
        #expect(!note.contains("Ladybug"))
    }
}
