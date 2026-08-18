pragma Singleton
import QtQuick

QtObject {
    id: root
    // Stubbed for waffle bar
    readonly property bool pomodoroRunning: false
    readonly property bool countdownRunning: false
    readonly property bool stopwatchRunning: false
    readonly property int pomodoroSecondsLeft: 0
    readonly property int countdownSecondsLeft: 0
    readonly property int stopwatchTime: 0
    readonly property bool pomodoroBreak: false
    readonly property bool pomodoroLongBreak: false
    readonly property int pomodoroCycle: 0
    readonly property int cyclesBeforeLongBreak: 4
    
    function togglePomodoro() {}
    function toggleCountdown() {}
    function toggleStopwatch() {}
}