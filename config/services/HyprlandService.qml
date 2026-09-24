// Hyprland-facing helpers: workspace lists per screen, and runtime settings
// writes for the Customise tab.
//
// Note (Chunk 0 finding F2): Hyprland 0.56 with a Lua config uses the
// non-legacy parser, so `hyprctl keyword` fails and everything must go through
// `hyprctl eval` with Lua. Hyprland.usingLua tells us which mode we are in.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
    id: root

    readonly property bool usingLua: Hyprland.usingLua

    // Workspaces belonging to a given Quickshell screen, sorted by id.
    // Hyprland.monitorFor() maps a ShellScreen to its HyprlandMonitor, and
    // workspace.monitor is that same object, so identity comparison is safe.
    function workspacesFor(screen) {
        if (!screen)
            return []

        var mon = Hyprland.monitorFor(screen)
        if (!mon)
            return []

        var out = []
        var ws = Hyprland.workspaces.values
        for (var i = 0; i < ws.length; i++) {
            if (ws[i].monitor === mon)
                out.push(ws[i])
        }
        out.sort(function (a, b) { return a.id - b.id })
        return out
    }

    // ── Runtime config writes ───────────────────────────────────────────────
    // One Process reused for every write; commands are queued by reassigning
    // and restarting, which is enough for UI-speed interactions.
    property Process _proc: Process {
        id: proc
        onExited: function (code) {
            if (code !== 0)
                console.warn("hyprctl eval failed:", code)
        }
    }

    // Emit Lua for the non-legacy parser, falling back to keywords for
    // hyprlang configs so this file works on either setup.
    function evalLua(code) {
        proc.command = ["hyprctl", "eval", code]
        proc.running = false
        proc.running = true
    }

    function keyword(name, value) {
        proc.command = ["hyprctl", "keyword", name, value]
        proc.running = false
        proc.running = true
    }

    // ── Named setters used by the Customise tab ─────────────────────────────
    function setDecoration(field, value) {
        if (usingLua)
            evalLua("hl.config({ decoration = { " + field + " = " + value + " } })")
        else
            keyword("decoration:" + field, String(value))
    }

    function setBlur(field, value) {
        if (usingLua)
            evalLua("hl.config({ decoration = { blur = { " + field + " = " + value + " } } })")
        else
            keyword("decoration:blur:" + field, String(value))
    }

    function setGeneral(field, value) {
        if (usingLua)
            evalLua("hl.config({ general = { " + field + " = " + value + " } })")
        else
            keyword("general:" + field, String(value))
    }

    function setAnimationsEnabled(enabled) {
        if (usingLua)
            evalLua("hl.config({ animations = { enabled = " + (enabled ? "true" : "false") + " } })")
        else
            keyword("animations:enabled", enabled ? "true" : "false")
    }

    // Re-apply the layerrule for our own surfaces (blur behind the bar/popups).
    function setLayerBlur(enabled) {
        if (usingLua)
            evalLua('hl.layer_rule({ match = { namespace = "quickshell" }, blur = ' +
                    (enabled ? "true" : "false") + ", ignore_alpha = 0.0 })")
    }
}
