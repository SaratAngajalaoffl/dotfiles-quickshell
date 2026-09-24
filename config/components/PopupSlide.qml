// Slide-in/out container shared by every popup. This is goal #5 — smooth
// animations when widgets open — in one place instead of per popup.
//
// Universal behaviour lives here: the animation, hover-to-open, self-hover
// tracking and close delay. A popup only wires its ShellState bool into `open`
// and puts its content inside.
//
//   PopupSlide {
//       edge: "right"
//       open: ShellState.audioOpen
//       // content
//   }
//
// Hover popups additionally bind `triggerHovered` and handle `closeRequested`.
import QtQuick
import "../theme"

Item {
    id: root

    // ── Required ────────────────────────────────────────────────────────────
    property string edge: "left"   // left | right | top | bottom
    property bool   open: false    // the ShellState.*Open bool for this popup

    // ── Hover-to-open (optional) ────────────────────────────────────────────
    property bool hoverEnabled:   false
    property bool triggerHovered: false  // bound to ShellState.*TriggerHovered

    // ── Timing ──────────────────────────────────────────────────────────────
    property int slideDuration: Theme.animDuration
    property int closeDelay:    Theme.hoverCloseDelay

    // ── Output ──────────────────────────────────────────────────────────────
    // Bind the PopupWindow/PanelWindow `visible` to this.
    property bool windowVisible: false

    // Emitted after closeDelay when hover leaves; the popup clears its bool.
    signal closeRequested()

    property bool _selfHovered: false

    // Visually open when the bool is set, or when hover is enabled and either
    // the trigger or the popup itself is hovered.
    readonly property bool effectiveOpen:
        open || (hoverEnabled && (triggerHovered || _selfHovered))

    default property alias content: inner.data

    clip: true

    onEffectiveOpenChanged: {
        if (effectiveOpen) {
            hoverCloseTimer.stop()
            windowVisible = true
        } else if (hoverEnabled) {
            // Delay so the pointer can travel from trigger to popup without
            // the popup flickering shut mid-journey.
            hoverCloseTimer.restart()
        } else {
            slideCloseTimer.restart()
        }
    }

    // Wait for the slide-out to finish before hiding the window (click path).
    Timer {
        id: slideCloseTimer
        interval: root.slideDuration + 20
        onTriggered: root.windowVisible = false
    }

    // Hover left — wait, then re-check before actually closing.
    Timer {
        id: hoverCloseTimer
        interval: root.closeDelay
        onTriggered: {
            if (!root.triggerHovered && !root._selfHovered) {
                root.windowVisible = false
                root.closeRequested()
            }
        }
    }

    Item {
        id: inner
        width:  parent.width
        height: parent.height

        x: root.effectiveOpen ? 0 : (root.edge === "left"   ? -width  :
                                     root.edge === "right"  ?  width  : 0)
        y: root.effectiveOpen ? 0 : (root.edge === "top"    ? -height :
                                     root.edge === "bottom" ?  height : 0)

        Behavior on x {
            NumberAnimation { duration: root.slideDuration; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            NumberAnimation { duration: root.slideDuration; easing.type: Easing.OutCubic }
        }

        // Self-hover tracking, available to every popup for free.
        HoverHandler {
            onHoveredChanged: root._selfHovered = hovered
        }
    }
}
