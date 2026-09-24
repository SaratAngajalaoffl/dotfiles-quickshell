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
    property int cornerRadiusSmall: 10
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
    property int popupWidth: 400
    property int networkPopupWidth: 480
    property int launcherWidth: 520
    property int launcherMaxHeight: 420

    // ── Control center ──────────────────────────────────────────────────────
    property int ccWidth: 560          // every page, so the panel keeps one shape
    property int ccHeight: 680
    property int ccPadding: 14
    property int ccRadius: 24          // bottom-left corner once expanded
    property int ccCardRadius: 18
    property int ccMorphDuration: 500

    // ── Island (center pill) ────────────────────────────────────────────────
    property int islandTop: 10            // gap from the top of the screen
    property int islandRestHeight: 30     // clock pill at rest
    property int islandPeekWidth: 540     // hover: media / clock / RAM
    property int islandPeekHeight: 72
    property int islandRadius: 24         // corner cap once taller than a pill
    property int islandMorphDuration: 450

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
