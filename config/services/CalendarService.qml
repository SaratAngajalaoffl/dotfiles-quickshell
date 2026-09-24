// Month grid for the dashboard calendar.
//
// Display-only for now (open question 4 in the migration doc): no CalDAV or
// Google events. What it does do properly is the arithmetic — weeks start on
// Monday and the grid is padded to whole weeks, which is where naive month
// views usually go wrong.
pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    // ── What is on screen ───────────────────────────────────────────────────
    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()   // 0-11

    readonly property var today: new Date()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var dayNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    readonly property string title: monthNames[viewMonth] + " " + viewYear

    // ── Grid ────────────────────────────────────────────────────────────────
    // [{ day, inMonth, isToday }] padded to a whole number of weeks.
    // JS getDay() is 0=Sunday; we want 0=Monday.
    function _mondayIndex(d) {
        return (d.getDay() + 6) % 7
    }

    function build() {
        var first = new Date(viewYear, viewMonth, 1)
        var daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate()
        var lead = _mondayIndex(first)

        var cells = []
        var prevDays = new Date(viewYear, viewMonth, 0).getDate()

        // Leading days from the previous month.
        for (var i = lead - 1; i >= 0; i--)
            cells.push({ day: prevDays - i, inMonth: false, isToday: false })

        for (var d = 1; d <= daysInMonth; d++) {
            cells.push({
                day: d,
                inMonth: true,
                isToday: d === today.getDate()
                         && viewMonth === today.getMonth()
                         && viewYear === today.getFullYear()
            })
        }

        // Trailing days so the grid is a whole number of weeks.
        var trail = (7 - (cells.length % 7)) % 7
        for (var t = 1; t <= trail; t++)
            cells.push({ day: t, inMonth: false, isToday: false })

        return cells
    }

    // Re-evaluated whenever the view or the day changes.
    readonly property var cells: {
        var _ = viewMonth + viewYear
        return build()
    }

    // ISO week number of the first row, for the week-number gutter.
    readonly property int firstWeekNumber: {
        var d = new Date(viewYear, viewMonth, 1)
        var target = new Date(d.valueOf())
        var dayNr = (d.getDay() + 6) % 7
        target.setDate(target.getDate() - dayNr + 3)
        var firstThursday = new Date(target.getFullYear(), 0, 4)
        var diff = target - firstThursday
        return 1 + Math.round((diff / 86400000 - 3 + ((firstThursday.getDay() + 6) % 7)) / 7)
    }

    function rows() { return Math.ceil(cells.length / 7) }

    function weekNumber(col) { return firstWeekNumber + col }

    // ── Navigation ──────────────────────────────────────────────────────────
    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear-- }
        else viewMonth--
    }

    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear++ }
        else viewMonth++
    }

    function todayMonth() {
        viewYear = today.getFullYear()
        viewMonth = today.getMonth()
    }

    readonly property string todayLabel: {
        var d = today
        return dayNames[(d.getDay() + 6) % 7] + " " + d.getDate() + " "
             + monthNames[d.getMonth()] + " " + d.getFullYear()
    }

    // ── Clock ───────────────────────────────────────────────────────────────
    property var now: new Date()

    property Timer _clock: Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }

    readonly property string clock: {
        var d = root.now
        return (d.getHours() < 10 ? "0" : "") + d.getHours() + ":"
             + (d.getMinutes() < 10 ? "0" : "") + d.getMinutes()
    }
}
