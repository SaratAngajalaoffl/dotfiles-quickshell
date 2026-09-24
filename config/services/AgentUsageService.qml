// Usage for the Agents widget: Claude and OpenCode Go subscription limits,
// and Bifrost gateway stats, from scripts/agent-usage.py. Credentials stay in
// the script — this only ever sees the numbers.
//
// Each source is fetched on its own: the subscriptions (Claude, OpenCode)
// are quick and polled every minute while the widget is on screen
// (`watching`), every few minutes otherwise; Bifrost's 7-day queries take ~15 s, so it is polled every five
// minutes regardless. refresh() fetches all of them now.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string script: Quickshell.shellDir + "/scripts/agent-usage.py"

    // Last result per source; see the script for the shape. Kept when a
    // later fetch fails outright, so the widget never blanks.
    property var claude: null
    property var opencode: null
    property var bifrost: null
    property date fetchedAt: new Date(0)
    readonly property bool claudeBusy: _claude.running
    readonly property bool opencodeBusy: _opencode.running
    readonly property bool bifrostBusy: _bifrost.running
    readonly property bool busy: claudeBusy || opencodeBusy || bifrostBusy

    // Set by the widget while it is visible.
    property bool watching: false
    onWatchingChanged: if (watching && Date.now() - fetchedAt.getTime() > 30000) _fetchSubscriptions()

    function refresh() {
        _fetchSubscriptions()
        _bifrost.fetch()
    }

    function _fetchSubscriptions() {
        _claude.fetch()
        _opencode.fetch()
    }

    component Fetch: Process {
        id: proc
        property string source
        function fetch() { if (!running) running = true }

        command: ["python3", root.script, source]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var out = JSON.parse(text)
                    root[proc.source] = out[proc.source]
                    root.fetchedAt = new Date(out.fetched_at)
                } catch (e) {
                    console.warn("agent-usage:", proc.source, "bad output:", e)
                }
            }
        }
    }

    property Fetch _claude: Fetch { source: "claude" }
    property Fetch _opencode: Fetch { source: "opencode" }
    property Fetch _bifrost: Fetch { source: "bifrost" }

    property Timer _subscriptionPoll: Timer {
        interval: root.watching ? 60000 : 300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._fetchSubscriptions()
    }

    property Timer _bifrostPoll: Timer {
        interval: 300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._bifrost.fetch()
    }
}
