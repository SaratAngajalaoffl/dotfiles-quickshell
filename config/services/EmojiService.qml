// Emoji database, parsed from the file rofi-emoji ships
// (/usr/share/rofi-emoji/all_emojis.txt) so the picker has the same ~5000
// entries without needing the plugin at runtime.
//
// Format, tab separated:
//   <glyph> <group> <subgroup> <name> <keyword | keyword | ...>
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string source: "/usr/share/rofi-emoji/all_emojis.txt"

    property var all: []
    property bool loaded: false

    // Distinct groups, in file order, for the category rail.
    property var groups: []

    // ── Load / parse ────────────────────────────────────────────────────────
    property FileView _file: FileView {
        path: root.source
        watchChanges: false
        onLoaded: root._parse(text())
        onLoadFailed: console.warn("emoji: cannot read", root.source)
    }

    function _parse(raw) {
        if (!raw)
            return
        var out = []
        var seen = {}
        var lines = raw.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (line === "")
                continue
            var f = line.split("\t")
            if (f.length < 4)
                continue
            var glyph = f[0]
            // Some entries are duplicate renderings of the same glyph.
            if (seen[glyph])
                continue
            seen[glyph] = true
            out.push({
                glyph:    glyph,
                group:    f[1] || "",
                name:     f[3] || "",
                keywords: (f[4] || "").toLowerCase()
            })
        }
        var gs = []
        var gseen = {}
        for (var j = 0; j < out.length; j++) {
            var g = out[j].group
            if (!gseen[g]) {
                gseen[g] = true
                gs.push(g)
            }
        }
        root.all = out
        root.groups = gs
        root.loaded = true
    }

    // Case-insensitive search over name + keywords, restricted to a group.
    function search(query, group) {
        var q = (query || "").toLowerCase()
        var out = []
        for (var i = 0; i < root.all.length; i++) {
            var e = root.all[i]
            if (group && group !== "" && e.group !== group)
                continue
            if (q === "" || e.name.toLowerCase().indexOf(q) !== -1
                || e.keywords.indexOf(q) !== -1) {
                out.push(e)
                if (out.length >= 400)
                    break
            }
        }
        return out
    }
}
