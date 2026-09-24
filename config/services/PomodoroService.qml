// Pomodoro timer (goal #4). Work / short break / long break, with the session
// state on disk so a shell restart does not lose a running timer.
//
// Completion raises a notification through NotificationService, which means it
// lands in the persistent notification panel rather than vanishing.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ── Configuration ───────────────────────────────────────────────────────
    property int workMinutes: 25
    property int shortMinutes: 5
    property int longMinutes: 15
    property int longEvery: 4
    property bool autoStartNext: false
    property bool notify: true

    // ── Session state ───────────────────────────────────────────────────────
    // phase: "work" | "short" | "long"
    property string phase: "work"
    property int remaining: workMinutes * 60
    property bool running: false
    property int completed: 0   // finished work sessions since last long break

    readonly property int totalSeconds: {
        if (phase === "work")  return workMinutes * 60
        if (phase === "short") return shortMinutes * 60
        return longMinutes * 60
    }

    // 0..1, for the ring.
    readonly property real progress: totalSeconds > 0
        ? 1 - (remaining / totalSeconds) : 0

    readonly property string clock: {
        var m = Math.floor(remaining / 60)
        var s = remaining % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    readonly property string phaseLabel: {
        if (phase === "work")  return "Focus"
        if (phase === "short") return "Short break"
        return "Long break"
    }

    // ── Tick ────────────────────────────────────────────────────────────────
    property Timer _timer: Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: root._tick()
    }

    function _tick() {
        if (root.remaining > 0) {
            root.remaining--
            return
        }
        root._complete()
    }

    function _complete() {
        root.running = false
        var finished = root.phase

        var message
        if (finished === "work") {
            root.completed++
            root.phase = (root.completed % root.longEvery === 0) ? "long" : "short"
            message = "Focus done — " + root.phaseLabel.toLowerCase() + " (" + root.clock + ")"
        } else {
            root.phase = "work"
            message = "Break over — back to focus (" + root.clock + ")"
        }

        root.remaining = root.totalSeconds
        root.save()

        // Goes through our own service, so it lands in the persistent panel
        // instead of vanishing like a plain notify-send.
        if (root.notify)
            NotificationService.notify("Pomodoro", message)

        if (root.autoStartNext)
            root.running = true
    }

    // ── Controls ────────────────────────────────────────────────────────────
    function start()  { if (!root.running) { root.running = true; root.save() } }
    function pause()  { root.running = false; root.save() }
    function toggle() { root.running ? root.pause() : root.start() }

    function reset() {
        root.running = false
        root.remaining = root.totalSeconds
        root.save()
    }

    function skip() {
        root.remaining = 0
        root._complete()
    }

    function setPhase(p) {
        root.running = false
        root.phase = p
        root.remaining = root.totalSeconds
        root.save()
    }

    // ── Persistence ─────────────────────────────────────────────────────────
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string stateFile: stateDir + "/pomodoro.json"

    function save() {
        _save.command = ["bash", "-c",
            "mkdir -p '" + root.stateDir + "' && printf '%s' \"$1\" > '" + root.stateFile + "'",
            "_", JSON.stringify({
                phase: root.phase,
                remaining: root.remaining,
                completed: root.completed,
                workMinutes: root.workMinutes,
                shortMinutes: root.shortMinutes,
                longMinutes: root.longMinutes,
                autoStartNext: root.autoStartNext
            })]
        _save.running = true
    }

    property Process _save: Process {}

    property Process _load: Process {
        command: ["cat", root.stateFile]
        stdout: StdioCollector { onStreamFinished: root._restore(text) }
    }

    function _restore(raw) {
        if (!raw)
            return
        try {
            var o = JSON.parse(raw)
            if (o.phase) root.phase = o.phase
            if (o.workMinutes) root.workMinutes = o.workMinutes
            if (o.shortMinutes) root.shortMinutes = o.shortMinutes
            if (o.longMinutes) root.longMinutes = o.longMinutes
            if (o.completed !== undefined) root.completed = o.completed
            if (o.autoStartNext !== undefined) root.autoStartNext = o.autoStartNext
            // A timer is not resumed across a restart: `remaining` is restored
            // but the clock stays paused, so the shell never ticks in the
            // background without the user asking.
            root.remaining = o.remaining !== undefined ? o.remaining : root.totalSeconds
        } catch (e) {
            console.log("PomodoroService: bad state file:", e)
        }
    }

    Component.onCompleted: _load.running = true
}
