// Clipboard history, backed by cliphist (already fed by the wl-paste watchers
// in Hyprland's autostart).
//
// Listing is `cliphist list`; restoring is `cliphist decode <id> | wl-copy`,
// run as a shell pipeline so binary (image) entries work too.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var entries: []      // { id, preview, isImage }
    property int maxPreview: 80
    property bool available: true

    // ── Listing ─────────────────────────────────────────────────────────────
    property string _buf: ""

    property Process _list: Process {
        command: ["cliphist", "list"]
        // Without an explicit stdout reader the output is discarded and the
        // list always looked empty.
        stdout: SplitParser {
            onRead: function (line) {
                if (line !== "")
                    root._buf += line + "\n"
            }
        }
        onExited: function (code) {
            if (code !== 0) {
                root.available = false
                root.entries = []
                root._buf = ""
                return
            }
            root.available = true
            root._parse(root._buf)
            root._buf = ""
        }
    }

    function refresh() {
        if (_list.running)
            return
        root._buf = ""
        _list.running = true
    }

    function _parse(raw) {
        if (!raw) {
            root.entries = []
            return
        }
        var out = []
        var lines = raw.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (line === "")
                continue
            // "42<TAB>the text" — images show as "42<TAB>[[ binary data ... ]]"
            var tab = line.indexOf("\t")
            if (tab === -1)
                continue
            var body = line.substring(tab + 1)
            var isImage = body.indexOf("[[ binary data") === 0
            out.push({
                id:      line.substring(0, tab),
                isImage: isImage,
                preview: isImage ? "Image" : body.substring(0, root.maxPreview)
            })
        }
        root.entries = out
    }

    // ── Actions ─────────────────────────────────────────────────────────────
    property Process _action: Process {
        onExited: function () { root.refresh() }
    }

    function _run(cmd) {
        if (_action.running)
            return
        _action.command = ["bash", "-c", cmd]
        _action.running = true
    }

    function copyEntry(id) {
        // Shell quote the id defensively — it always comes from cliphist, but
        // it is still interpolated into a command string.
        var safe = String(id).replace(/[^0-9]/g, "")
        if (safe === "")
            return
        _run("cliphist decode " + safe + " | wl-copy")
    }

    function deleteEntry(id) {
        var safe = String(id).replace(/[^0-9]/g, "")
        if (safe === "")
            return
        _run("cliphist delete " + safe)
    }

    function clearAll() {
        _run("cliphist wipe")
    }
}
