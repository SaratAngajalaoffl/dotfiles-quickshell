// Spotify control + search, ported from the eww widget (Chunk 5e).
//
// Two back ends, exactly as eww had it:
//   * playback — `soloist ctl`, the daemon's own CLI. No Web API token needed
//     and it is what MPRIS-free control was built for.
//   * search  — the Spotify Web API Client Credentials flow. The Client ID and
//     Secret come from gnome-keyring (service `spotify-search`), never from a
//     file in this repo.
//
// The keyring lookups and the whole API dance happen in
// services/spotify-search.sh, so the credential never passes through QML.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string scriptDir: home + "/.config/quickshell/scripts"
    readonly property string searchScript: scriptDir + "/spotify-search.sh"
    readonly property string ctlScript: scriptDir + "/spotify-ctl.sh"
    readonly property string playlistsScript: scriptDir + "/spotify-playlists.sh"

    // ── Playback state ──────────────────────────────────────────────────────
    property bool   running: false
    property string state: "stopped"       // playing | paused | stopped
    property string title: ""
    property string artist: ""
    property string artUrl: ""
    property int    positionMs: 0
    property int    durationMs: 1
    property bool   shuffle: false
    property string repeat: "off"

    readonly property bool playing: state === "playing"

    readonly property real progress: durationMs > 0
        ? Math.min(1, positionMs / durationMs) : 0

    // ── Search ──────────────────────────────────────────────────────────────
    // Each result: {kind: track|artist|album|playlist, uri, name, artist, art}.
    property var results: []
    property bool searching: false
    property string searchError: ""

    // ── Playlists ───────────────────────────────────────────────────────────
    // Pinned in scripts/spotify-playlists.json; the script adds cover art.
    property var playlists: []

    property Process _playlistRead: Process {
        command: ["bash", root.playlistsScript]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.playlists = JSON.parse(text)
                } catch (e) {
                    root.playlists = []
                }
            }
        }
    }

    // ── Polling ─────────────────────────────────────────────────────────────
    property Process _poll: Process {
        command: ["bash", "-c",
            "export PATH=\"$HOME/bin:$HOME/.local/bin:$PATH\"; " +
            "soloist ctl now --json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root._parseState(text)
        }
    }

    property Timer _pollTimer: Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: if (!root._poll.running) root._poll.running = true
    }

    function _parseState(raw) {
        if (!raw) {
            root.running = false
            root.state = "stopped"
            return
        }
        try {
            var o = JSON.parse(raw)
            root.running = true
            root.state = o.status === "playing" ? "playing"
                       : o.status === "paused"  ? "paused" : "stopped"

            var item = o.item || {}
            var dec = item.decorations || {}
            root.title = (dec.identity && dec.identity.name) || ""

            var creators = dec.creators || []
            var names = []
            for (var i = 0; i < creators.length; i++) {
                var c = creators[i].entity || {}
                var cd = c.decorations || {}
                if (cd.identity && cd.identity.name)
                    names.push(cd.identity.name)
            }
            root.artist = names.join(", ")

            var vis = dec.visual_identity || {}
            var covers = vis.cover || []
            root.artUrl = ""
            for (var j = 0; j < covers.length; j++) {
                if (covers[j].size === "large") { root.artUrl = covers[j].url; break }
                if (!root.artUrl) root.artUrl = covers[j].url
            }

            root.positionMs = (o.position && o.position.position_ms) || 0
            root.durationMs = (dec.playback && dec.playback.duration_ms) || 1
            root.shuffle = !!(o.options && o.options.shuffle)
            root.repeat = (o.options && o.options.repeat) || "off"
        } catch (e) {
            root.running = false
            root.state = "stopped"
        }
    }

    // ── Transport ───────────────────────────────────────────────────────────

    property Process _ctl: Process {}

    function _run(args) {
        _ctl.command = ["bash", "-c",
            "export PATH=\"$HOME/bin:$HOME/.local/bin:$PATH\"; \"$@\"",
            "_", root.ctlScript].concat(args)
        _ctl.running = false
        _ctl.running = true
    }

    function toggle()  { _run(["toggle"]) }
    function next()    { _run(["next"]) }
    function previous(){ _run(["prev"]) }
    function playUri(uri) { _run(["play-uri", uri]) }
    function seekMs(ms)   { _run(["seek", String(Math.round(ms))]) }

    function setShuffle(on) {
        _run(["shuffle", on ? "on" : "off"])
    }

    function cycleRepeat() {
        var next = root.repeat === "off" ? "context"
                 : root.repeat === "context" ? "track" : "off"
        _run(["repeat", next])
    }

    // ── Search ──────────────────────────────────────────────────────────────

    // One search runs at a time. Typing while one is in flight only records
    // the newest query (`_wanted`); when the running search ends, a stale one
    // is followed straight away by the newest. (Previously the new command
    // was set on a process that was still running, so it never ran and the
    // list kept showing an older query's results.)
    property string _wanted: ""
    property string _running: ""

    property Process _search: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var o = JSON.parse(text)
                    if (o.query === root._wanted) {
                        root.results = o.results || []
                        root.searchError = ""
                    }
                } catch (e) { /* reported from onExited */ }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") console.warn("spotify-search:", text.trim())
        }
        onExited: function (code) {
            if (root._wanted !== root._running && root._wanted !== "") {
                root._start()
                return
            }
            root.searching = false
            // `secret-tool` exits 0 with empty output when the entry is absent,
            // and the script then fails a few lines later, so point at the
            // keyring rather than showing a generic error.
            if (code !== 0)
                root.searchError = "Search failed — are the Spotify secrets in the keyring?"
        }
    }

    function search(query) {
        query = (query || "").trim()
        root._wanted = query.length < 2 ? "" : query
        if (root._wanted === "") {
            root.results = []
            root.searching = false
            return
        }
        root.searching = true
        if (!_search.running) root._start()
    }

    function _start() {
        root._running = root._wanted
        _search.command = ["bash", root.searchScript, root._running]
        _search.running = true
    }

    function clearSearch() {
        root._wanted = ""
        root.results = []
        root.searching = false
        root.searchError = ""
    }

    Component.onCompleted: _playlistRead.running = true
}
