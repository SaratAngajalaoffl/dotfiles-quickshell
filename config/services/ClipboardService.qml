// Clipboard history, backed by cliphist (already fed by the wl-paste watchers
// in Hyprland's autostart).
//
// Listing is `cliphist list`; restoring is `cliphist decode <id> | wl-copy`,
// run as a shell pipeline so binary (image) entries work too.
//
// Image entries get a thumbnail: after each listing, the newest images are
// decoded once into thumbDir (keyed by cliphist id, which never changes for
// an entry), and files for entries that are gone are pruned.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var entries: []      // { id, preview, isImage, thumb, imgW, imgH }
    property int maxPreview: 80
    property bool available: true

    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/quickshell/cliphist"
    // Only the newest images get thumbnails; older ones keep the text label.
    readonly property int maxThumbs: 60
    // Bumped when a decode pass finishes, so Images retry files that were
    // still missing when their delegate was created.
    property int thumbsRevision: 0
    // False while a decode pass is running, so Images don't try (and warn
    // about) files that haven't been written yet.
    property bool thumbsReady: false

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
            root._decodeThumbs([])      // history wiped: prune every thumbnail
            return
        }
        var out = []
        var thumbs = []
        var lines = raw.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (line === "")
                continue
            // "42<TAB>the text" — images show as "42<TAB>[[ binary data ... ]]"
            var tab = line.indexOf("\t")
            if (tab === -1)
                continue
            var id = line.substring(0, tab)
            var body = line.substring(tab + 1)
            // "[[ binary data 18 KiB png 402x537 ]]"
            var m = body.match(/^\[\[ binary data (.+?) (\w+) (\d+)x(\d+) \]\]$/)
            var isImage = body.indexOf("[[ binary data") === 0
            var thumb = ""
            var preview = body.substring(0, root.maxPreview)
            if (isImage) {
                preview = m ? m[2].toUpperCase() + " \u00b7 " + m[3] + "\u00d7" + m[4] + " \u00b7 " + m[1]
                            : "Image"
                if (m && thumbs.length < root.maxThumbs) {
                    var ext = m[2].toLowerCase().replace(/[^a-z0-9]/g, "")
                    thumb = root.thumbDir + "/" + id + "." + ext
                    thumbs.push(id + "." + ext)
                }
            }
            out.push({
                id: id, isImage: isImage, preview: preview, thumb: thumb,
                imgW: m ? parseInt(m[3], 10) : 0,
                imgH: m ? parseInt(m[4], 10) : 0
            })
        }
        root.entries = out
        root._decodeThumbs(thumbs)
    }

    // ── Thumbnails ──────────────────────────────────────────────────────────
    property Process _thumbs: Process {
        onExited: {
            root.thumbsRevision++
            root.thumbsReady = true
        }
    }

    // Decode missing thumbnails, and delete ones whose entry is gone. Each
    // arg is "<id>.<ext>", with both parts already reduced to [0-9]/[a-z0-9].
    function _decodeThumbs(names) {
        if (_thumbs.running)
            return
        root.thumbsReady = false
        _thumbs.command = ["bash", "-c",
            'dir="$1"; shift; mkdir -p "$dir" || exit 1; ' +
            'declare -A keep; ' +
            'for n in "$@"; do keep[$n]=1; f="$dir/$n"; ' +
            '  if [ ! -s "$f" ]; then ' +
            '    cliphist decode "${n%%.*}" > "$f.tmp" 2>/dev/null && mv -f "$f.tmp" "$f"; ' +
            '    rm -f "$f.tmp"; fi; done; ' +
            'for f in "$dir"/*; do [ -e "$f" ] || continue; ' +
            '  [ -n "${keep[${f##*/}]}" ] || rm -f "$f"; done',
            "_", root.thumbDir].concat(names)
        _thumbs.running = true
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
