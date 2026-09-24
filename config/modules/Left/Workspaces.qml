// Workspace pills for one monitor.
//
// Sized to its content; TopBar clamps it. Pills show active / occupied / empty
// / urgent, click to activate, scroll to cycle workspaces.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../theme"
import "../../services"
import "../../components"

Row {
    id: root

    required property var screen

    spacing: Theme.wsSpacing
    // Show a fixed count of pills like waybar did (persistent_workspaces: 5),
    // plus any workspace that actually exists.
    property int persistentCount: 5

    readonly property var _live: HyprlandService.workspacesFor(root.screen)

    // Merge persistent 1..N with live workspaces, de-duplicated, sorted.
    readonly property var _ids: {
        var seen = ({})
        var out = []
        for (var i = 1; i <= root.persistentCount; i++) {
            seen[i] = true
            out.push(i)
        }
        for (var j = 0; j < _live.length; j++) {
            var id = _live[j].id
            if (!seen[id]) {
                seen[id] = true
                out.push(id)
            }
        }
        out.sort(function (a, b) { return a - b })
        return out
    }

    function _wsFor(id) {
        for (var i = 0; i < _live.length; i++)
            if (_live[i].id === id)
                return _live[i]
        return null
    }

    Repeater {
        model: root._ids

        delegate: Rectangle {
            id: pill
            required property var modelData

            readonly property var ws: root._wsFor(modelData)
            readonly property bool isActive:   ws ? ws.active   : false
            readonly property bool isUrgent:   ws ? ws.urgent   : false
            readonly property bool isOccupied: ws ? ws.toplevels.values.length > 0 : false

            width: isActive ? Theme.wsActiveWidth : Theme.wsDotSize
            height: Theme.wsDotSize
            radius: Theme.wsRadius
            anchors.verticalCenter: parent.verticalCenter

            color: isUrgent   ? Theme.wsUrgent
                 : isActive   ? Theme.wsActive
                 : isOccupied ? Theme.wsOccupied
                 : Theme.wsEmpty

            Behavior on width {
                NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }

            HoverHandler {
                id: hover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    if (pill.ws)
                        pill.ws.activate()
                    else
                        Hyprland.dispatch("workspace " + pill.modelData)
                }
            }

            // Scroll to cycle workspaces, same as waybar's scroll behaviour.
            WheelHandler {
                onWheel: function (event) {
                    var delta = event.angleDelta.y > 0 ? -1 : 1
                    Hyprland.dispatch("workspace e" + (delta > 0 ? "+" : "-") + "1")
                }
            }
        }
    }
}
