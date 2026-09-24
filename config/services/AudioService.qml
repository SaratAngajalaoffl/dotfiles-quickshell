// Audio: default sink/source state, volume and mute.
//
// Uses Quickshell's Pipewire service rather than shelling out to wpctl, so
// values are live with no polling loop.
//
// IMPORTANT: `Pipewire.defaultAudioSink` hands back a node object whose `audio`
// bindings are NOT populated until the object is *tracked*. Reading
// `sink.audio.volume` off the bare default produced a permanent 0% /
// `ready=false` (verified — the node existed, its volume did not). A
// PwObjectTracker is what actually binds the underlying object, so the tracked
// node is the one to read from.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

QtObject {
    id: root

    // Binds the objects we read from. Without this, audio bindings stay empty.
    property PwObjectTracker tracker: PwObjectTracker {
        objects: [root.sink, root.source].filter(function (o) { return !!o })
    }

    readonly property var sink:   Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property bool ready: Pipewire.ready

    // ── Sink (output) ───────────────────────────────────────────────────────
    readonly property var sinkAudio: sink ? sink.audio : null

    readonly property real volume: sinkAudio ? sinkAudio.volume : 0
    readonly property bool muted:  sinkAudio ? sinkAudio.muted  : false
    readonly property int  volumePercent: Math.round(volume * 100)

    readonly property string sinkName:
        sink ? (sink.nickname || sink.description || sink.name || "") : ""

    // ── Source (input / mic) ────────────────────────────────────────────────
    readonly property var sourceAudio: source ? source.audio : null

    readonly property real sourceVolume: sourceAudio ? sourceAudio.volume : 0
    readonly property bool sourceMuted:  sourceAudio ? sourceAudio.muted  : false
    readonly property int  sourcePercent: Math.round(sourceVolume * 100)

    readonly property string sourceName:
        source ? (source.nickname || source.description || source.name || "") : ""

    // ── Glyph, mirroring waybar's wireplumber formatting ────────────────────
    readonly property string glyph: {
        if (muted || volumePercent === 0) return "\uf026"
        if (volumePercent < 34) return "\uf027"
        return "\uf028"
    }

    // Devices for the picker.
    //
    // These cannot be `readonly property var` bound to a helper function:
    // a property whose initializer calls a plain function never re-evaluates,
    // so the list froze at startup (it kept showing a Chrome stream node that
    // had long since gone). Reading instead of caching keeps it live.
    function sinkList() { return _nodes(function (n) { return n.isSink && !n.isStream && n.audio }) }
    function sourceList() { return _nodes(function (n) { return !n.isSink && !n.isStream && n.audio }) }

    // Kept as bindings for QML consumers, but rebuilt on every nodes change.
    readonly property var sinks: {
        // Touch the model so this re-evaluates when nodes appear/disappear.
        var _ = Pipewire.nodes.values.length
        return sinkList()
    }

    readonly property var sources: {
        var _ = Pipewire.nodes.values.length
        return sourceList()
    }

    function _nodes(pred) {
        var out = []
        var nodes = Pipewire.nodes.values
        for (var i = 0; i < nodes.length; i++)
            if (pred(nodes[i]))
                out.push(nodes[i])
        return out
    }

    // ── Actions ─────────────────────────────────────────────────────────────
    function setVolume(v) {
        if (sinkAudio)
            sinkAudio.volume = Math.max(0, Math.min(1.5, v))
    }

    function adjustVolume(delta) {
        if (sinkAudio)
            setVolume(sinkAudio.volume + delta)
    }

    function toggleMute() {
        if (sinkAudio)
            sinkAudio.muted = !sinkAudio.muted
    }

    function toggleSourceMute() {
        if (sourceAudio)
            sourceAudio.muted = !sourceAudio.muted
    }

    function setSourceVolume(v) {
        if (sourceAudio)
            sourceAudio.volume = Math.max(0, Math.min(1.5, v))
    }

    function setDefaultSink(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node
    }

    function setDefaultSource(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node
    }
}
