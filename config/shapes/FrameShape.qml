// Full-screen frame: left, right and bottom edges drawn as ONE window per
// monitor, with the screen area punched out via the even-odd fill rule.
//
// The top edge is the bar window's job (it owns the exclusive zone), so this
// frame is inset by notchHeight at the top.
//
// Validated in the Chunk 0 spike: `ctx.fill("evenodd")` cuts the hole
// correctly with both contours wound the same way.
import Quickshell
import QtQuick
import "../theme"

PanelWindow {
    id: root

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    margins {
        top: Theme.notchHeight
        left: Theme.borderWidth
        right: Theme.borderWidth
        bottom: Theme.borderWidth
    }

    Canvas {
        id: frame
        anchors.fill: parent

        onWidthChanged:  requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: Theme
            function onBarBgChanged()  { frame.requestPaint() }
            function onBorderWidthChanged() { frame.requestPaint() }
            function onCornerRadiusChanged() { frame.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var w = width
            var h = height
            var t = Theme.borderWidth
            var r = Theme.cornerRadius

            ctx.beginPath()

            // Outer rounded rect
            ctx.moveTo(r, 0)
            ctx.lineTo(w - r, 0)
            ctx.arcTo(w, 0, w, r, r)
            ctx.lineTo(w, h - r)
            ctx.arcTo(w, h, w - r, h, r)
            ctx.lineTo(r, h)
            ctx.arcTo(0, h, 0, h - r, r)
            ctx.lineTo(0, r)
            ctx.arcTo(0, 0, r, 0, r)
            ctx.closePath()

            // Inner rounded rect — even-odd punches this out.
            ctx.moveTo(t + r, t)
            ctx.lineTo(t + r, h - t - r)
            ctx.arcTo(t + r, h - t, t + r + r, h - t, r)
            ctx.lineTo(w - t - r, h - t)
            ctx.arcTo(w - t, h - t, w - t, h - t - r, r)
            ctx.lineTo(w - t, t + r)
            ctx.arcTo(w - t, t, w - t - r, t, r)
            ctx.lineTo(t + r + r, t)
            ctx.arcTo(t + r, t, t + r, t + r, r)
            ctx.closePath()

            ctx.fillStyle = Theme.barBg
            ctx.fill("evenodd")
        }
    }
}
