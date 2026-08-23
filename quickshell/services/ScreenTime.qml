pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Per-app screen-time tracking (Niri).
 * Polls the focused window via `niri msg -j windows`, attributes elapsed
 * time to the app + hour-of-day bucket, and persists a JSON file per day under
 * ~/.cache/quickshell/screenTime. Self-contained: no Config / common modules.
 * Ported from Waffle iNiR ScreenTime (logic preserved, deps swapped).
 */
Singleton {
    id: root

    readonly property bool enabled: true
    property bool ready: false

    property var _todayData: null
    property string _currentAppId: ""
    property string _currentAppName: ""
    property real _lastTickTime: 0
    property real _lastPersistMs: 0
    readonly property int _persistIntervalMs: 30000
    property string _currentDate: ""
    property bool _dirty: false
    property var _rangeCache: ({})
    property var _focusedWindow: null

    readonly property int pollIntervalSeconds: 5

    readonly property string screenTimePath: Quickshell.env("HOME") + "/.cache/quickshell/screenTime"

    readonly property var todayData: _todayData
    readonly property string currentAppId: _currentAppId
    readonly property string currentAppName: _currentAppName

    signal dataChanged()
    signal rangeLoaded(int days, var data)

    Component.onCompleted: {
        _currentDate = _dateString(new Date())
        mkdirProc.running = true
        _loadTodayFromFile()
    }

    function _loadTodayFromFile() {
        const path = _todayFilePath()
        startupReadProc.command = ["/usr/bin/bash", "-c", `test -f "${path}" && cat "${path}" || echo "__NOFILE__"`]
        startupReadProc.running = true
    }

    Timer {
        id: pollTimer
        interval: root.pollIntervalSeconds * 1000
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!niriPollProc.running)
                niriPollProc.running = true
        }
    }

    Timer {
        id: dayRolloverTimer
        interval: 60000
        running: root.enabled
        repeat: true
        onTriggered: {
            const now = root._dateString(new Date())
            if (now !== root._currentDate) {
                root._persistToday()
                root._currentDate = now
                root._todayData = root._emptyDay(now)
                root._currentAppId = ""
                root._currentAppName = ""
                root._lastTickTime = Date.now()
                root._lastPersistMs = Date.now()
                root._rangeCache = ({})
                root.dataChanged()
            }
        }
    }

    function _tick() {
        if (!root.enabled)
            return

        const now = Date.now()
        let appId = ""
        let appName = ""

        const win = root._focusedWindow
        if (win && win.app_id) {
            appId = win.app_id
            appName = _humanizeAppId(appId)
        }

        const elapsed = root._lastTickTime > 0
            ? Math.round((now - root._lastTickTime) / 1000)
            : 0
        const intervalStart = root._lastTickTime
        root._lastTickTime = now

        if (elapsed <= 0 || elapsed > 60) {
            root._currentAppId = appId
            root._currentAppName = appName
            return
        }

        if (!root._todayData)
            root._todayData = _emptyDay(root._currentDate)

        if (appId.length > 0) {
            root._todayData.totalSeconds += elapsed

            const key = appId.toLowerCase().replace(/[^a-z0-9-]/g, "")
            if (!root._todayData.apps[key])
                root._todayData.apps[key] = { name: appName, seconds: 0, originalId: appId, hourly: new Array(24).fill(0) }
            const appEntry = root._todayData.apps[key]
            if (!appEntry.originalId)
                appEntry.originalId = appId
            if (!appEntry.hourly || appEntry.hourly.length !== 24)
                appEntry.hourly = new Array(24).fill(0)
            appEntry.seconds += elapsed

            const perHour = _distributeElapsed(intervalStart, now)
            for (const h in perHour) {
                const secs = perHour[h]
                root._todayData.hourly[h] = (root._todayData.hourly[h] || 0) + secs
                appEntry.hourly[h] = (appEntry.hourly[h] || 0) + secs
            }

            root._dirty = true
        }

        root._currentAppId = appId
        root._currentAppName = appName
        root._todayData = Object.assign({}, root._todayData)
        root._rangeCache = ({})
        root.dataChanged()

        if (root._dirty && (now - root._lastPersistMs) >= root._persistIntervalMs) {
            root._persistToday()
            root._dirty = false
            root._lastPersistMs = now
        }
    }

    function _distributeElapsed(startMs, endMs) {
        const result = ({})
        if (!(startMs > 0) || endMs <= startMs)
            return result
        let cursor = startMs
        let guard = 0
        while (cursor < endMs && guard < 26) {
            const d = new Date(cursor)
            const hour = d.getHours()
            const next = new Date(cursor)
            next.setMinutes(60, 0, 0)
            const boundary = Math.min(next.getTime(), endMs)
            const secs = Math.round((boundary - cursor) / 1000)
            if (secs > 0)
                result[hour] = (result[hour] || 0) + secs
            cursor = boundary
            guard++
        }
        return result
    }

    function getToday() {
        return root._todayData || _emptyDay(root._currentDate)
    }

    function requestDays(count) {
        if (count <= 1) {
            root.rangeLoaded(1, getToday())
            return
        }
        let script = ""
        const now = new Date()
        for (let i = 1; i < count; i++) {
            const d = new Date(now)
            d.setDate(d.getDate() - i)
            const path = `${root.screenTimePath}/${_dateString(d)}.json`
            script += `cat "${path}" 2>/dev/null || echo "{}"; echo "---DELIM---";\n`
        }
        rangeReadProc._requestedDays = count
        rangeReadProc.command = ["/usr/bin/bash", "-c", script]
        rangeReadProc.running = true
    }

    function getCachedDays(count) {
        return root._rangeCache[count] || null
    }

    function getAppList(days) {
        const data = days <= 1 ? getToday() : (root._rangeCache[days] || getToday())
        const apps = data.apps || {}
        const list = []
        const keys = Object.keys(apps)
        for (let i = 0; i < keys.length; i++) {
            const key = keys[i]
            list.push({ id: key, name: apps[key].name || key, seconds: apps[key].seconds || 0, originalId: apps[key].originalId || key })
        }
        list.sort((a, b) => b.seconds - a.seconds)
        return list
    }

    function formatDuration(totalSeconds) {
        if (totalSeconds < 60)
            return totalSeconds + "s"
        const hours = Math.floor(totalSeconds / 3600)
        const mins = Math.floor((totalSeconds % 3600) / 60)
        if (hours > 0)
            return hours + "h " + mins + "m"
        return mins + "m"
    }

    function _emptyDay(dateStr) {
        return { date: dateStr, totalSeconds: 0, hourly: new Array(24).fill(0), apps: {} }
    }

    function _humanizeAppId(id) {
        const parts = id.split(".")
        const name = parts.length > 1 ? parts[parts.length - 1] : id
        return name.replace(/[-_]/g, " ").replace(/\b\w/g, function (c) { return c.toUpperCase() }).trim()
    }

    function _dateString(d) {
        const y = d.getFullYear()
        const m = String(d.getMonth() + 1).padStart(2, "0")
        const day = String(d.getDate()).padStart(2, "0")
        return `${y}-${m}-${day}`
    }

    function _todayFilePath() {
        return `${root.screenTimePath}/${root._currentDate}.json`
    }

    function _persistToday() {
        if (!root._todayData)
            return
        const url = Qt.resolvedUrl(_todayFilePath())
        if (todayFileView.path !== url)
            todayFileView.path = url
        todayFileView.setText(JSON.stringify(root._todayData, null, 2))
    }

    function _mergeDays(todayData, rawText) {
        const result = {
            totalSeconds: todayData.totalSeconds || 0,
            hourly: (todayData.hourly || []).slice(),
            apps: {}
        }
        if (!result.hourly.length)
            result.hourly = new Array(24).fill(0)

        const todayApps = todayData.apps || {}
        const todayKeys = Object.keys(todayApps)
        for (let i = 0; i < todayKeys.length; i++) {
            const key = todayKeys[i]
            result.apps[key] = {
                name: todayApps[key].name,
                seconds: todayApps[key].seconds,
                originalId: todayApps[key].originalId || key,
                hourly: (todayApps[key].hourly && todayApps[key].hourly.length === 24)
                    ? todayApps[key].hourly.slice() : new Array(24).fill(0)
            }
        }

        const sections = rawText.split("---DELIM---").filter(s => s.trim().length > 0 && s.trim() !== "{}")
        for (let i = 0; i < sections.length; i++) {
            try {
                const dayData = JSON.parse(sections[i].trim())
                if (!dayData || !dayData.totalSeconds)
                    continue
                result.totalSeconds += dayData.totalSeconds || 0
                if (dayData.hourly) {
                    for (let h = 0; h < 24; h++)
                        result.hourly[h] = (result.hourly[h] || 0) + (dayData.hourly[h] || 0)
                }
                if (dayData.apps) {
                    const keys = Object.keys(dayData.apps)
                    for (let k = 0; k < keys.length; k++) {
                        const key = keys[k]
                        if (!result.apps[key]) {
                            result.apps[key] = { name: dayData.apps[key].name || key, seconds: 0, originalId: dayData.apps[key].originalId || key, hourly: new Array(24).fill(0) }
                        }
                        result.apps[key].seconds += dayData.apps[key].seconds || 0
                        const dh = dayData.apps[key].hourly
                        if (dh && dh.length === 24) {
                            for (let h = 0; h < 24; h++)
                                result.apps[key].hourly[h] += (dh[h] || 0)
                        }
                    }
                }
            } catch (e) {}
        }
        return result
    }

    function getHourBreakdown(hour, days) {
        const data = days <= 1 ? getToday() : (root._rangeCache[days] || getToday())
        const apps = data.apps || {}
        const keys = Object.keys(apps)
        const list = []
        for (let i = 0; i < keys.length; i++) {
            const key = keys[i]
            const hourly = apps[key].hourly
            const secs = (hourly && hourly.length === 24) ? (hourly[hour] || 0) : 0
            if (secs > 0)
                list.push({ id: key, name: apps[key].name || key, seconds: secs, originalId: apps[key].originalId || key })
        }
        list.sort((a, b) => b.seconds - a.seconds)
        return list
    }

    Process {
        id: mkdirProc
        running: false
        command: ["mkdir", "-p", root.screenTimePath]
    }

    Process {
        id: niriPollProc
        running: false
        command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                let win = null
                try {
                    const arr = JSON.parse((text ?? "").trim())
                    if (Array.isArray(arr)) {
                        for (let i = 0; i < arr.length; i++) {
                            if (arr[i].is_focused) {
                                win = arr[i]
                                break
                            }
                        }
                    }
                } catch (e) {}
                root._focusedWindow = win
                root._tick()
            }
        }
    }

    FileView {
        id: todayFileView
        path: ""
    }

    Process {
        id: startupReadProc
        command: ["/usr/bin/bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                root._dirty = false
                if (text.trim() === "__NOFILE__" || text.trim().length === 0) {
                    root._todayData = root._emptyDay(root._currentDate)
                } else {
                    try {
                        root._todayData = JSON.parse(text.trim())
                    } catch (e) {
                        root._todayData = root._emptyDay(root._currentDate)
                    }
                }
                root._lastTickTime = Date.now()
                root._lastPersistMs = Date.now()
                root.ready = true
                root.dataChanged()
            }
        }
    }

    Process {
        id: rangeReadProc
        property int _requestedDays: 1
        command: ["/usr/bin/bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const merged = root._mergeDays(root.getToday(), text)
                const cache = {}
                cache[rangeReadProc._requestedDays] = merged
                root._rangeCache = Object.assign({}, root._rangeCache, cache)
                root.rangeLoaded(rangeReadProc._requestedDays, merged)
            }
        }
    }
}
