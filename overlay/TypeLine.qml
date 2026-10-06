import QtQuick
import QtQuick.Effects

// One line of HUD text that types itself on, with a block cursor while typing.
Item {
    id: root
    property string full: ""
    property real t0: 0          // seconds after the intro starts
    property real cps: 40        // characters per second
    property real clock: 0
    property color col: "white"
    property string family: ""
    property real size: 20
    property real spacing: 0
    property real ybase: 0    // SVG-style baseline (design px)
    property bool glow: false
    property real op: 1

    readonly property string shown: full.substring(0, Math.max(0, Math.min(full.length, Math.floor((clock - t0) * cps))))
    readonly property bool typing: clock >= t0 && shown.length < full.length

    x: 220
    y: ybase - size * 0.82
    width: txt.contentWidth
    height: size * 1.25

    layer.enabled: root.glow
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: root.col
        shadowBlur: 0.6
        shadowOpacity: 0.85
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        autoPaddingEnabled: true
    }

    Text {
        id: txt
        text: root.shown
        color: root.col
        opacity: root.op
        font.family: root.family
        font.pixelSize: root.size
        font.letterSpacing: root.spacing
        renderType: Text.NativeRendering
    }
    Rectangle {
        visible: root.typing && (Math.floor(root.clock * 8) % 2 === 0)
        x: txt.contentWidth + 4
        y: 2
        width: root.size * 0.55
        height: root.size
        color: root.col
    }
}
