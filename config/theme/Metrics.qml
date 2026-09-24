// Layout constants. Sizes only — no colours, no behaviour.
//
// Anything the Customise tab can change at runtime lives here as a normal
// property so the UI can write to it and every widget re-lays out live.
pragma Singleton
import QtQuick

QtObject {
    // ── Frame / bar geometry ────────────────────────────────────────────────
    property int borderWidth: 6      // thickness of the screen frame
    property int cornerRadius: 17    // outer frame corner
    property int notchRadius: 15     // notch bottom corners
    property int notchHeight: 40
    property int exclusionGap: 34    // reserved space under the bar

    // ── Notch sizing ────────────────────────────────────────────────────────
    // Each notch sizes to its content, clamped between min and max.
    property int notchPadding: 16

    property int lNotchMinWidth: 180
    property int lNotchMaxWidth: 360
    property int cNotchMinWidth: 300
    property int cNotchMaxWidth: 360
    property int rNotchMinWidth: 180
    property int rNotchMaxWidth: 360

    // ── Popup sizing ────────────────────────────────────────────────────────
    property int popupPadding: 16
    property int dashboardWidth: 900
    property int dashboardHeight: 520
    property int notificationsWidth: 400
    property int networkPopupWidth: 480
    property int launcherWidth: 520
    property int launcherMaxHeight: 420
    property int emojiWidth: 360
    property int emojiMaxHeight: 400

    // ── Workspace pills ─────────────────────────────────────────────────────
    property int wsDotSize: 10
    property int wsActiveWidth: 24
    property int wsSpacing: 6
    property int wsPadding: 8
    property int wsRadius: 16

    // ── Animation ───────────────────────────────────────────────────────────
    // Popup slide duration. The Customise tab exposes this.
    property int animDuration: 320
    property int animFast: 150
    property int hoverCloseDelay: 250

    // ── Fonts ───────────────────────────────────────────────────────────────
    property string fontFamily: "FiraCode Nerd Font"
    property int fontSize: 12
    property int fontSizeSmall: 11
    property int fontSizeLarge: 13

    // ── Behaviour toggles ───────────────────────────────────────────────────
    property bool barEnabled: true
    property bool focusMode: false    // collapses bar to an edge strip
}
