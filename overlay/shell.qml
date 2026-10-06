import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Astraea HUD overlay: a click-through layer between Omarchy's wallpaper and your windows.
// It reads data.json, watches which wallpaper is active, and animates that scene's HUD.
ShellRoot {
    id: root
    property var data: null
    property string current: ""

    Process {
        id: loader
        command: ["cat", Quickshell.shellDir + "/data.json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { root.data = JSON.parse(text) } catch (e) { console.log("astraea-hud: bad data.json: " + e) } }
        }
    }

    // which wallpaper is showing? e.g. 01-astraea-section-9-rooftop.png -> "astraea-section-9-rooftop"
    Process {
        id: watcher
        command: ["readlink", "-f", Quickshell.env("HOME") + "/.local/state/omarchy/current/background"]
        stdout: StdioCollector {
            onStreamFinished: {
                var f = text.trim().split("/").pop()
                var k = f.replace(/^\d+-/, "").replace(/\.\w+$/, "")
                if (k !== root.current) root.current = k
            }
        }
    }
    Timer { interval: 1500; running: true; repeat: true; triggeredOnStart: true; onTriggered: if (!watcher.running) watcher.running = true }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "astraea-hud"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}          // empty input region: clicks go straight through
            Hud { anchors.fill: parent; cfg: root.data; sceneKey: root.current }
        }
    }
}
