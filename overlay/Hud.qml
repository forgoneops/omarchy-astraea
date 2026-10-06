import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell

// Animated HUD for one screen. Designed on a 2560x1440 canvas (same coordinates as the baked HUD),
// scaled/cropped exactly like the wallpaper (PreserveAspectCrop).
Item {
    id: hud
    property var cfg: null
    property string sceneKey: ""

    readonly property var scene: (cfg && cfg.scenes) ? cfg.scenes[sceneKey] : undefined
    readonly property var theme: (scene !== undefined && cfg.themes) ? cfg.themes[scene.theme] : undefined
    readonly property bool active: scene !== undefined && theme !== undefined
    visible: active

    // ---- colours (resolved to real colours so r/g/b can be used)
    readonly property var tc: theme ? theme.type : ({notice: "#fff", headline: "#fff", subline: "#fff", accent: "#fff", rank: "#fff", location: "#fff", kit: "#fff", surname: "#fff", tribute: "#fff"})
    property color accent: theme ? theme.accent : "#ffb62e"
    property color second: theme ? theme.secondary : "#aef8ff"
    property color gradHi: theme ? theme.grad_hi : "#ffe27a"
    property color gradLo: theme ? theme.grad_lo : "#c77f2a"
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }

    FontLoader { id: fTek;  source: "file://" + Quickshell.shellDir + "/../assets/fonts/Tektur-Medium.ttf" }
    FontLoader { id: fMono; source: "file://" + Quickshell.shellDir + "/../assets/fonts/GeistMono-Regular.ttf" }
    readonly property string tek: fTek.name
    readonly property string mono: fMono.name

    // ---- clock: fast only while the intro plays or a glitch burst is on, slow otherwise (cheap at idle)
    property double t0: Date.now()
    property real clock: 0
    property real burstUntil: -1
    property real seed: 0.37
    readonly property bool burst: clock < burstUntil
    readonly property bool intro: clock < 4.8
    readonly property int sec: Math.floor(clock)

    onSceneKeyChanged: { t0 = Date.now(); clock = 0; burstUntil = -1 }
    Timer {
        interval: (hud.intro || hud.burst) ? 33 : 500
        running: hud.active; repeat: true
        onTriggered: hud.clock = (Date.now() - hud.t0) / 1000
    }
    Timer {
        id: burstTimer
        interval: 7000; running: hud.active; repeat: true
        onTriggered: { hud.clock = (Date.now() - hud.t0) / 1000; hud.seed = Math.random(); hud.burstUntil = hud.clock + 0.16; interval = 7000 + Math.random() * 9000 }
    }

    // ---- stage: 2560x1440 design space, cover-scaled
    readonly property real s: Math.max(width / 2560, height / 1440)
    Item {
        id: stage
        width: 2560; height: 1440
        scale: hud.s
        transformOrigin: Item.TopLeft
        x: (hud.width - 2560 * hud.s) / 2
        y: (hud.height - 1440 * hud.s) / 2

        // corner brackets
        Repeater {
            model: [[60, 60, 1, 1], [2500, 60, -1, 1], [60, 1380, 1, -1], [2500, 1380, -1, -1]]
            Item {
                required property var modelData
                Rectangle { x: modelData[2] > 0 ? modelData[0] : modelData[0] - 70; y: modelData[1] - (modelData[3] < 0 ? 0 : 0); width: 70; height: 3; color: hud.accent }
                Rectangle { x: modelData[0] - (modelData[2] > 0 ? 0 : 3); y: modelData[3] > 0 ? modelData[1] : modelData[1] - 70; width: 3; height: 70; color: hud.accent }
            }
        }

        // ruler
        Rectangle { x: 96; y: 150; width: 1.2; height: 1140; color: hud.second; opacity: 0.55 }
        Repeater {
            model: 29
            Item {
                required property int index
                readonly property bool major: index % 5 === 0
                Rectangle { x: 96; y: 150 + index * 40; width: major ? 18 : 8; height: major ? 1.4 : 1; color: hud.second; opacity: major ? 0.8 : 0.4 }
                Text {
                    visible: major
                    x: 124; y: 150 + index * 40 - 8
                    text: ("000" + index * 40).slice(-3)
                    color: hud.second; opacity: 0.55
                    font.family: hud.mono; font.pixelSize: 14
                }
            }
        }

        // notice + hairline
        TypeLine { full: hud.cfg ? hud.cfg.text.notice : ""; t0: 0.0; cps: 60; clock: hud.clock; col: hud.tc.notice; family: hud.mono; size: 20; spacing: 6; ybase: 172 }
        Rectangle { x: 220; y: 198; height: 1.5; width: Math.min(790, hud.clock * 1400); color: hud.accent }

        // headline (+ chroma ghost, + glitch slice)
        TypeLine { x: hud.burst ? 206 : 216; full: hud.cfg ? hud.cfg.text.headline : ""; t0: 0.3; cps: 28; clock: hud.clock; col: hud.second; op: 0.5; family: hud.tek; size: 60; spacing: 3; ybase: 282 }
        TypeLine { full: hud.cfg ? hud.cfg.text.headline : ""; t0: 0.3; cps: 28; clock: hud.clock; col: hud.tc.headline; family: hud.tek; size: 60; spacing: 3; ybase: 282; glow: true }
        Item {
            visible: hud.burst
            readonly property real sy: 244 + Math.floor(hud.seed * 40)
            x: 200; y: sy; width: 900; height: 9; clip: true
            TypeLine { x: 36; y: 234 - parent.sy; full: hud.cfg ? hud.cfg.text.headline : ""; t0: 0.3; cps: 28; clock: hud.clock; col: hud.second; family: hud.tek; size: 60; spacing: 3; ybase: 282 }
        }
        TypeLine { full: hud.cfg ? hud.cfg.text.subline : ""; t0: 1.05; cps: 42; clock: hud.clock; col: hud.tc.subline; family: hud.tek; size: 29; spacing: 2; ybase: 342 }
        TypeLine { full: hud.cfg ? hud.cfg.text.accent : ""; t0: 1.7; cps: 55; clock: hud.clock; col: hud.tc.accent; family: hud.mono; size: 22; spacing: 3; ybase: 392; glow: true }
        TypeLine {
            full: hud.cfg ? ("RANK " + hud.cfg.character.rank + "  /  CALLSIGN: " + hud.cfg.character.callsign + "  /  ONLINE") : ""
            t0: 2.2; cps: 70; clock: hud.clock; col: hud.tc.rank; op: 0.9; family: hud.mono; size: 20; spacing: 4; ybase: 438
        }

        // scene readout: each wallpaper has its own location + kit
        TypeLine { full: hud.scene ? ("> " + hud.scene.location) : ""; t0: 2.7; cps: 60; clock: hud.clock; col: hud.tc.location; family: hud.mono; size: 20; ybase: 498 }
        Repeater {
            model: hud.scene ? hud.scene.kit : []
            TypeLine {
                required property int index
                required property string modelData
                full: "> " + modelData; t0: 3.1 + index * 0.4; cps: 60; clock: hud.clock; col: hud.tc.kit; op: 0.95; family: hud.mono; size: 20; ybase: 534 + index * 30
            }
        }

        // ticking packet line (changes every second) + barcode + timecode
        Text {
            visible: hud.clock > 4.2
            x: 220; y: 656 - 16 * 0.82
            color: hud.second; opacity: 0.8
            font.family: hud.mono; font.pixelSize: 16; font.letterSpacing: 2
            text: "ERR 0x" + ((0x7F00 + hud.sec * 3791) & 0xFFFF).toString(16).toUpperCase() + "  /  PACKET LOSS " + (6 + (hud.sec * 7) % 11 + (hud.burst ? 9 : 0)) + "%  /  RESYNC"
        }
        Row {
            x: 220; y: 686; spacing: 3
            visible: hud.clock > 4.0
            opacity: hud.burst ? 0.9 : 0.5
            Repeater {
                model: 46
                Rectangle { required property int index; width: [2, 3, 2, 5, 2, 3][(index * 7) % 6]; height: 26; color: hud.second }
            }
        }
        Text {
            x: 1010 - width; y: 226 - 16 * 0.82
            color: hud.accent; opacity: 0.85
            font.family: hud.mono; font.pixelSize: 16; font.letterSpacing: 3
            text: "REC  04:47:" + ("0" + (hud.sec % 60)).slice(-2) + ":" + ("0" + (Math.floor(hud.clock * 24) % 24)).slice(-2)
        }
        Rectangle { x: 1022; y: 216; width: 10; height: 10; radius: 5; color: "#ff4d5e"; visible: hud.sec % 2 === 0 }

        // ---- wordmark: column-sweep reveal, chroma split, burst slices
        readonly property real cell: 18
        readonly property real prog: Math.max(0, Math.min(1, (hud.clock - 0.2) / 1.1))
        readonly property int rowA: Math.floor(hud.seed * 7)
        readonly property int rowB: (rowA + 3) % 7
        Repeater {   // cyan ghost
            model: hud.cfg ? hud.cfg.cells : []
            Rectangle {
                required property var modelData
                visible: modelData[0] <= stage.prog * hud.cfg.cellCount
                x: 220 + modelData[0] * stage.cell + 1 + (hud.burst ? -16 : -6); y: 1020 + modelData[1] * stage.cell + 1
                width: stage.cell - 2; height: stage.cell - 2; color: hud.second
            }
        }
        Repeater {   // accent ghost
            model: hud.cfg ? hud.cfg.cells : []
            Rectangle {
                required property var modelData
                visible: modelData[0] <= stage.prog * hud.cfg.cellCount
                x: 220 + modelData[0] * stage.cell + 1 + (hud.burst ? 16 : 6); y: 1020 + modelData[1] * stage.cell + 1
                width: stage.cell - 2; height: stage.cell - 2; color: hud.accent; opacity: 0.45
            }
        }
        Repeater {   // main, vertical gradient
            model: hud.cfg ? hud.cfg.cells : []
            Rectangle {
                required property var modelData
                visible: modelData[0] <= stage.prog * hud.cfg.cellCount
                x: 220 + modelData[0] * stage.cell + 1; y: 1020 + modelData[1] * stage.cell + 1
                width: stage.cell - 2; height: stage.cell - 2
                color: hud.mix(hud.gradHi, hud.gradLo, modelData[1] / 6)
            }
        }
        Repeater {   // burst: two rows knocked sideways
            model: hud.cfg ? hud.cfg.cells : []
            Rectangle {
                required property var modelData
                visible: hud.burst && (modelData[1] === stage.rowA || modelData[1] === stage.rowB)
                x: 220 + modelData[0] * stage.cell + 1 + (modelData[1] === stage.rowA ? 1 : -1) * (24 + hud.seed * 24); y: 1020 + modelData[1] * stage.cell + 1
                width: stage.cell - 2; height: stage.cell - 2; color: modelData[1] === stage.rowA ? hud.second : hud.accent
            }
        }

        Rectangle { x: 220; y: 1196; width: 738; height: 1.5; color: hud.accent; opacity: Math.max(0, Math.min(1, (hud.clock - 1.0) * 2)) }
        Text {
            x: 220; y: 1240 - 22 * 0.82
            text: hud.cfg ? hud.cfg.character.surname.split("").join(" ") : ""
            color: hud.tc.surname; opacity: Math.max(0, Math.min(1, (hud.clock - 1.2) * 2))
            font.family: hud.mono; font.pixelSize: 22; font.letterSpacing: 22
        }
        Text {
            x: 262; y: 1276 - 15 * 0.82
            text: hud.cfg ? hud.cfg.text.tribute : ""
            color: hud.tc.tribute; opacity: Math.max(0, Math.min(1, (hud.clock - 1.6) * 2)) * 0.9
            font.family: hud.mono; font.pixelSize: 15; font.letterSpacing: 2
        }

        // caduceus (Hermes tribute)
        Shape {
            x: 234; y: 1268; scale: 0.2; transformOrigin: Item.TopLeft
            opacity: Math.max(0, Math.min(1, (hud.clock - 1.6) * 2))
            ShapePath {
                strokeColor: hud.accent; strokeWidth: 3; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathSvg { path: "M0 -60 L0 70" }
                PathSvg { path: "M0 -40 C30 -70 70 -62 86 -80 M0 -32 C30 -52 60 -44 74 -58 M0 -24 C24 -38 48 -30 60 -40" }
                PathSvg { path: "M0 -40 C-30 -70 -70 -62 -86 -80 M0 -32 C-30 -52 -60 -44 -74 -58 M0 -24 C-24 -38 -48 -30 -60 -40" }
                PathSvg { path: "M0 60 C28 40 -28 20 0 0 C28 -20 -28 -35 0 -45" }
            }
        }

        // Astraea's star emblem
        Item {
            x: 1078; y: 1110
            readonly property real r: 59.5
            Shape {
                ShapePath {
                    strokeColor: hud.accent; strokeWidth: 2.1
                    fillColor: Qt.rgba(hud.accent.r, hud.accent.g, hud.accent.b, 0.18)
                    PathSvg { path: "M0 -59.5 L9.5 -9.5 L59.5 0 L9.5 9.5 L0 59.5 L-9.5 9.5 L-59.5 0 L-9.5 -9.5 Z" }
                }
                ShapePath {
                    strokeColor: hud.accent; strokeWidth: 1.3; fillColor: "transparent"; strokeStyle: ShapePath.DashLine; dashPattern: [3, 7]
                    PathAngleArc { centerX: 0; centerY: 0; radiusX: 72.6; radiusY: 72.6; startAngle: 0; sweepAngle: 360 }
                }
            }
            Shape {
                rotation: -24
                ShapePath {
                    strokeColor: hud.accent; strokeWidth: 1; fillColor: "transparent"
                    PathAngleArc { centerX: 0; centerY: 0; radiusX: 92; radiusY: 29.7; startAngle: 0; sweepAngle: 360 }
                }
            }
            Rectangle { x: 80 - 3; y: -37 - 3; width: 6; height: 6; radius: 3; color: hud.accent }
        }
    }
}
