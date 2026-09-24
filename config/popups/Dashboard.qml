// Dashboard: the large panel behind the top-left bar area, with tabs.
//
//   Home      — calendar, pomodoro, date/time
//   Customise — runtime appearance settings (goal #4)
//
// Rendered in a PanelWindow (see PopupLayer's LargePopup) so Hyprland blurs it.
import QtQuick
import "../theme"
import "../state"
import "../services"
import "../components"
import QtQuick.Layouts

Item {
    id: root

    implicitWidth: Theme.dashboardWidth
    implicitHeight: Theme.dashboardHeight

    readonly property var tabs: [
        { id: "home", label: "Home", glyph: "\uf015" },
        { id: "customise", label: "Customise", glyph: "\uf013" }
    ]

    PopupPanel {
        id: panel
        width: parent.width
        height: parent.height
        background: Theme.popupBg

        customHeader: Item {
            width: parent.width

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: root.tabs

                    delegate: Rectangle {
                        required property var modelData

                        anchors.verticalCenter: parent.verticalCenter
                        width: tabLabel.implicitWidth + 24
                        height: 28
                        radius: Theme.cornerRadiusSmall
                        color: ShellState.dashboardTab === modelData.id
                             ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                             : tabHover.hovered ? Theme.hover : "transparent"

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.glyph
                                color_: ShellState.dashboardTab === modelData.id
                                      ? Theme.accent : Theme.subtext0
                                font.pixelSize: Theme.fontSize
                            }

                            Text {
                                id: tabLabel
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: ShellState.dashboardTab === modelData.id
                                     ? Theme.accent : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: ShellState.dashboardTab === modelData.id
                            }
                        }

                        HoverHandler { id: tabHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: ShellState.dashboardTab = modelData.id }
                    }
                }
            }

            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: CalendarService.clock
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        // StackLayout reports implicitHeight 0, so the panel's content column
        // would collapse; give the tab area an explicit height instead of
        // relying on implicit sizing.
        StackLayout {
            width: parent.width
            height: Theme.dashboardHeight
                  - panel.headerHeight - Theme.popupPadding * 2
            currentIndex: ShellState.dashboardTab === "customise" ? 1 : 0

            HomeTab  { width: parent.width; height: parent.height }
            SettingsTab { width: parent.width; height: parent.height }
        }
    }

    // ── Home ────────────────────────────────────────────────────────────────
    component HomeTab: Item {
        Row {
            anchors.fill: parent
            spacing: 16

            // Calendar
            Column {
                width: 380
                height: parent.height
                spacing: 8

                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: CalendarService.title
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                    }

                    Item { width: parent.width - 240; height: 1 }

                    IconButton {
                        glyph: "\uf060"; size: 26
                        onActivated: CalendarService.prevMonth()
                    }
                    IconButton {
                        glyph: "\uf111"; size: 26
                        onActivated: CalendarService.todayMonth()
                    }
                    IconButton {
                        glyph: "\uf061"; size: 26
                        onActivated: CalendarService.nextMonth()
                    }
                }

                // Header row: week-number gutter + day names
                Row {
                    width: parent.width
                    spacing: 2

                    Text {
                        width: 26; height: 20
                        text: "wk"
                        color: Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Repeater {
                        model: CalendarService.dayNames
                        delegate: Text {
                            required property var modelData
                            width: (parent.parent.width - 26 - 2 * 7) / 7
                            height: 20
                            text: modelData
                            color: Theme.subtext0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                // Month grid, with a week-number gutter
                Grid {
                    id: monthGrid
                    width: parent.width
                    columns: 8   // week number + 7 days
                    spacing: 2
                    readonly property int cellW: (width - spacing * 7) / 8
                    readonly property int cellH: 34

                    Repeater {
                        model: {
                            // Interleave a week-number cell before every 7 days.
                            var cells = CalendarService.cells
                            var rows = CalendarService.rows()
                            var out = []
                            for (var r = 0; r < rows; r++) {
                                out.push({ week: CalendarService.weekNumber(r), day: null })
                                for (var c = 0; c < 7; c++) {
                                    var idx = r * 7 + c
                                    out.push(idx < cells.length
                                        ? { week: -1, day: cells[idx] }
                                        : { week: -1, day: null })
                                }
                            }
                            return out
                        }

                        delegate: Item {
                            required property var modelData

                            width: modelData.week >= 0 ? 26 : monthGrid.cellW
                            height: monthGrid.cellH

                            // Week-number cell
                            Text {
                                visible: modelData.week >= 0
                                anchors.centerIn: parent
                                text: modelData.week >= 0 ? modelData.week : ""
                                color: Theme.overlay0
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                            }

                            // Day cell
                            Rectangle {
                                visible: modelData.week < 0 && modelData.day !== null
                                anchors.fill: parent
                                radius: Theme.cornerRadiusSmall
                                color: modelData.day && modelData.day.isToday
                                     ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                                     : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day ? modelData.day.day : ""
                                    color: !modelData.day ? "transparent"
                                         : modelData.day.isToday ? Theme.accent
                                         : modelData.day.inMonth ? Theme.text
                                         : Theme.overlay0
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.bold: modelData.day ? modelData.day.isToday : false
                                }
                            }
                        }
                    }
                }

                Divider { width: parent.width }

                Text {
                    text: CalendarService.todayLabel
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }

                Text {
                    width: parent.width
                    text: "No events — calendar is display-only."
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                width: 1
                height: parent.height
                color: Theme.divider
            }

            // Pomodoro
            PomodoroCard {
                width: parent.width - 380 - 16 - 1
                height: parent.height
            }
        }
    }

    // ── Pomodoro card ───────────────────────────────────────────────────────
    component PomodoroCard: Column {
        spacing: 12

        Text {
            text: "Pomodoro"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
            font.bold: true
        }

        // Ring + clock
        Item {
            width: parent.width
            height: 180

            Canvas {
                id: ring
                anchors.centerIn: parent
                width: 170
                height: 170

                Connections {
                    target: PomodoroService
                    function onProgressChanged() { ring.requestPaint() }
                    function onPhaseChanged() { ring.requestPaint() }
                    function onRemainingChanged() { ring.requestPaint() }
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var cx = width / 2, cy = height / 2
                    var r = width / 2 - 10
                    var lw = 10

                    ctx.lineWidth = lw
                    ctx.lineCap = "round"

                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.strokeStyle = Theme.surface
                    ctx.stroke()

                    ctx.beginPath()
                    ctx.arc(cx, cy, r, -Math.PI / 2,
                            -Math.PI / 2 + Math.PI * 2 * PomodoroService.progress)
                    ctx.strokeStyle = Theme.accent
                    ctx.stroke()
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: PomodoroService.clock
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 34
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: PomodoroService.phaseLabel
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }

        // Controls
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            IconButton {
                glyph: PomodoroService.running ? "\uf04c" : "\uf04b"
                size: 34
                glyphSize: Theme.fontSizeLarge
                active: PomodoroService.running
                onActivated: PomodoroService.toggle()
            }
            IconButton {
                glyph: "\uf04d"; size: 34; glyphSize: Theme.fontSizeLarge
                onActivated: PomodoroService.skip()
            }
            IconButton {
                glyph: "\uf021"; size: 34; glyphSize: Theme.fontSizeLarge
                onActivated: PomodoroService.reset()
            }
        }

        // Phase picker
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            Repeater {
                model: [
                    { id: "work",  label: "Focus" },
                    { id: "short", label: "Short" },
                    { id: "long",  label: "Long" }
                ]

                delegate: Rectangle {
                    required property var modelData

                    width: phaseLabel.implicitWidth + 16
                    height: 24
                    radius: Theme.cornerRadiusSmall
                    color: PomodoroService.phase === modelData.id
                         ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20)
                         : phaseHover.hovered ? Theme.hover : Theme.surface

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        id: phaseLabel
                        anchors.centerIn: parent
                        text: modelData.label
                        color: PomodoroService.phase === modelData.id
                             ? Theme.accent : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    HoverHandler { id: phaseHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: PomodoroService.setPhase(modelData.id) }
                }
            }
        }

        Divider { width: parent.width }

        Text {
            text: PomodoroService.completed + " focus session(s) completed"
            color: Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }

        SettingRow {
            label: "Auto-start next"
            labelWidth: 140
            Toggle {
                checked: PomodoroService.autoStartNext
                onToggled: function (v) { PomodoroService.autoStartNext = v; PomodoroService.save() }
            }
        }

        SettingRow {
            label: "Notify on finish"
            labelWidth: 140
            Toggle {
                checked: PomodoroService.notify
                onToggled: function (v) { PomodoroService.notify = v; PomodoroService.save() }
            }
        }

        Item { width: 1; height: 1 }
    }

    // ── Customise ───────────────────────────────────────────────────────────
    component SettingsTab: Flickable {
        contentWidth: width
        contentHeight: settingsColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: settingsColumn
            width: parent.width
            spacing: 2

            // ── Blur ────────────────────────────────────────────────────────
            SectionHeader { text: "Blur" }

            SettingRow {
                label: "Enabled"
                Toggle {
                    checked: SettingsService.blurEnabled
                    onToggled: function (v) { SettingsService.blurEnabled = v; SettingsService.commit() }
                }
            }

            SettingRow {
                label: "Size"
                hint: SettingsService.blurSize
                Slider {
                    width: 240
                    value: (SettingsService.blurSize - 1) / 19
                    onMoved: function (v) {
                        SettingsService.blurSize = 1 + Math.round(v * 19)
                        SettingsService.commit()
                    }
                }
            }

            SettingRow {
                label: "Passes"
                hint: SettingsService.blurPasses
                Slider {
                    width: 240
                    value: (SettingsService.blurPasses - 1) / 4
                    onMoved: function (v) {
                        SettingsService.blurPasses = 1 + Math.round(v * 4)
                        SettingsService.commit()
                    }
                }
            }

            // ── Opacity ─────────────────────────────────────────────────────
            SectionHeader { text: "Opacity" }

            SettingRow {
                label: "Active window"
                hint: Math.round(SettingsService.activeOpacity * 100) + "%"
                Slider {
                    width: 240
                    value: SettingsService.activeOpacity
                    onMoved: function (v) {
                        SettingsService.activeOpacity = v
                        SettingsService.commit()
                    }
                }
            }

            SettingRow {
                label: "Inactive window"
                hint: Math.round(SettingsService.inactiveOpacity * 100) + "%"
                Slider {
                    width: 240
                    value: SettingsService.inactiveOpacity
                    onMoved: function (v) {
                        SettingsService.inactiveOpacity = v
                        SettingsService.commit()
                    }
                }
            }

            // ── Layout ──────────────────────────────────────────────────────
            SectionHeader { text: "Layout" }

            SettingRow {
                label: "Gaps inner"
                hint: SettingsService.gapsIn
                Slider {
                    width: 240
                    value: SettingsService.gapsIn / 40
                    onMoved: function (v) {
                        SettingsService.gapsIn = Math.round(v * 40)
                        SettingsService.commit()
                    }
                }
            }

            SettingRow {
                label: "Gaps outer"
                hint: SettingsService.gapsOut
                Slider {
                    width: 240
                    value: SettingsService.gapsOut / 40
                    onMoved: function (v) {
                        SettingsService.gapsOut = Math.round(v * 40)
                        SettingsService.commit()
                    }
                }
            }

            SettingRow {
                label: "Corner radius"
                hint: SettingsService.rounding
                Slider {
                    width: 240
                    value: SettingsService.rounding / 30
                    onMoved: function (v) {
                        SettingsService.rounding = Math.round(v * 30)
                        SettingsService.commit()
                    }
                }
            }

            SettingRow {
                label: "Animations"
                Toggle {
                    checked: SettingsService.animationsEnabled
                    onToggled: function (v) { SettingsService.animationsEnabled = v; SettingsService.commit() }
                }
            }

            // ── Terminal (kitty) ────────────────────────────────────────────
            SectionHeader { text: "Terminal" }

            SettingRow {
                label: "Cursor trail"
                hint: SettingsService.cursorTrail
                Slider {
                    width: 240
                    value: SettingsService.cursorTrail / 20
                    onMoved: function (v) {
                        SettingsService.cursorTrail = Math.round(v * 20)
                        SettingsService.commit()
                    }
                }
            }

            SettingRow {
                label: "Background opacity"
                hint: Math.round(SettingsService.backgroundOpacity * 100) + "%"
                Slider {
                    width: 240
                    value: SettingsService.backgroundOpacity
                    onMoved: function (v) {
                        SettingsService.backgroundOpacity = v
                        SettingsService.commit()
                    }
                }
            }

            SettingRow {
                label: "Font size"
                hint: SettingsService.fontSize.toFixed(1)
                Slider {
                    width: 240
                    value: (SettingsService.fontSize - 7) / 15
                    onMoved: function (v) {
                        SettingsService.fontSize = 7 + v * 15
                        SettingsService.commit()
                    }
                }
            }

            // ── Shell ───────────────────────────────────────────────────────
            SectionHeader { text: "Shell" }

            SettingRow {
                label: "Animation duration"
                hint: SettingsService.animDuration + " ms"
                Slider {
                    width: 240
                    value: (SettingsService.animDuration - 100) / 700
                    onMoved: function (v) {
                        SettingsService.animDuration = 100 + Math.round(v * 700)
                        SettingsService.save()
                    }
                }
            }

            SettingRow {
                label: "Do not disturb"
                Toggle {
                    checked: NotificationService.dnd
                    onToggled: function (v) { NotificationService.dnd = v }
                }
            }

            Divider { width: parent.width; height: 1 }

            Item {
                width: parent.width
                height: 44

                IconButton {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: "\uf021"
                    label: "Reset to defaults"
                    onActivated: SettingsService.reset()
                }
            }
        }
    }

    component SectionHeader: Text {
        width: parent ? parent.width : 0
        topPadding: 10
        bottomPadding: 4
        leftPadding: 8
        text: ""
        font.capitalization: Font.AllUppercase
        color: Theme.accent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
    }
}
