pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import "../singletons" as QsSingletons

Singleton {
    id: root

    // ── Native wifi device selection ─────────────────────────────────────────
    // Prefer a Station-mode wifi device; fall back to any wifi device if mode is
    // not exposed. Guards against a phantom / AP-mode / p2p device being first.
    readonly property var wifiDev: Networking.devices.values.find(d =>
        d && d.type === DeviceType.Wifi &&
        (d.mode === undefined || d.mode === WifiDeviceMode.Station)
    ) ?? null

    readonly property var nativeNetworks: wifiDev ? wifiDev.networks.values : []

    // ── Public API (names preserved for UI compatibility) ────────────────────
    readonly property list<AccessPoint> networks: []

    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool scanning: rescanProc.running

    readonly property bool connected: active !== null
    readonly property string ssid: active ? active.ssid : "Not Connected"
    readonly property int signalStrength: active ? active.strength : 0

    property var savedNetworks: []
    property bool pollingActive: true

    // Surfaces native connection failures (bad password, timeout, etc.) so they
    // are not silently dropped. A future UI may bind this.
    signal connectionFailed(string reason)

    // ── Adapter: native WifiNetwork -> old .ssid/.strength/.active/.isSecure ──
    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject?.name ?? ""
        readonly property string bssid: ""            // native WifiNetwork exposes no bssid
        readonly property int strength: lastIpcObject?.signalStrength ?? 0
        readonly property int frequency: 0            // native exposes none
        readonly property bool active: lastIpcObject?.connected ?? false
        readonly property string security: (lastIpcObject?.security !== undefined) ? String(lastIpcObject.security) : ""
        // isSecure treats every non-Open security as secured, INCLUDING
        // WifiSecurityType.Unknown. ASSUMPTION (unverified): Unknown ==
        // encrypted-but-undetermined; safer to show as secured than open.
        readonly property bool isSecure: lastIpcObject?.security !== undefined && lastIpcObject.security !== WifiSecurityType.Open
    }

    Component {
        id: apComp
        AccessPoint {}
    }

    // One-shot cleanup timer factory for per-attempt connect handlers
    // (disconnects failure/success handlers if neither signal fires).
    Component {
        id: cleanupTimerComp
        Timer {
            interval: 8000
            running: true
            repeat: false
            property var onFire
            onTriggered: { if (onFire) onFire() }
        }
    }

    // ── Rebuild the adapter list from native networks ────────────────────────
    // Dedupe by SSID (prefer the connected one). Keeps the ListView stable and
    // yields one row per SSID regardless of whether the native model is
    // per-BSSID or per-SSID.
    function rebuildNetworks() {
        const native = Array.from(root.nativeNetworks)
        const byName = new Map()
        for (const n of native) {
            const name = n.name ?? ""
            if (!name) continue
            const ex = byName.get(name)
            if (!ex || (n.connected && !ex.connected))
                byName.set(name, n)
        }
        const chosen = Array.from(byName.values())

        const rNetworks = root.networks
        const destroyed = rNetworks.filter(rn =>
            !chosen.find(n => n.name === rn.lastIpcObject?.name))
        for (const rn of destroyed) {
            rNetworks.splice(rNetworks.indexOf(rn), 1)
            rn.destroy()
        }
        for (const n of chosen) {
            const match = rNetworks.find(rn => rn.lastIpcObject?.name === n.name)
            if (match) match.lastIpcObject = n
            else rNetworks.push(apComp.createObject(root, { lastIpcObject: n }))
        }
    }

    onNativeNetworksChanged: root.rebuildNetworks()
    Component.onCompleted: root.rebuildNetworks()

    // ── Controls ─────────────────────────────────────────────────────────────
    function enableWifi(enabled: bool): void {
        Networking.wifiEnabled = enabled
    }

    function toggleWifi(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled
    }

    function rescanWifi(): void {
        // Native exposes no one-shot scan(); nmcli --rescan triggers a hardware
        // scan that the native model observes. `scanning` honestly tracks this
        // process (no invented timer).
        rescanProc.running = true
    }

    function connectToNetwork(ssid: string, password: string): void {
        if (!ssid || ssid.trim().length === 0) {
            console.error("[Network] Invalid SSID: empty")
            return
        }
        // Injection guard (defends the nmcli branch below).
        const dangerous = [";", "`", "$", "|", "&", "\n", "\r", "\\"]
        for (const c of dangerous) {
            if (ssid.includes(c)) {
                console.error("[Network] Invalid SSID: contains dangerous character")
                return
            }
        }

        const net = root.nativeNetworks.find(n => n.name === ssid) ?? null

        if (password && password.length > 0) {
            // New secured network: use nmcli (kept per project rule).
            connectProc.exec(["nmcli", "dev", "wifi", "connect", ssid, "password", password])
        } else if (net) {
            let done = false
            // Known/saved network: native connect. Wire failure AND success
            // cleanup PER ATTEMPT so no handler leaks, and a late failure from a
            // previous tap is not dropped (each attempt owns its own handlers;
            // no shared _connectingNet that gets silently retargeted).
            const failHandler = function (reason) {
                cleanup()
                root.connectionFailed(ConnectionFailReason.toString(reason))
            }
            const okHandler = function () {
                if (net.connected) cleanup()
            }
            const cleanup = function () {
                // Guard against double-run: failHandler, okHandler and the 8s
                // timer can all fire close together; a second run would touch an
                // already-destroyed cleanupTimer. Idempotent by design.
                if (done) return
                done = true
                net.connectionFailed.disconnect(failHandler)
                net.connectedChanged.disconnect(okHandler)
                if (cleanupTimer) {
                    cleanupTimer.onFire = null
                    cleanupTimer.destroy()
                }
            }
            net.connectionFailed.connect(failHandler)
            net.connectedChanged.connect(okHandler)
            // Safety net: drop the handlers after 8s if neither signal fired
            // (covers genuinely dropped signals). Legitimate cleanup, not a UI state.
            const cleanupTimer = cleanupTimerComp.createObject(root)
            cleanupTimer.onFire = cleanup
            net.connect()
        } else {
            // Fallback: saved connection by profile name.
            connectProc.exec(["nmcli", "connection", "up", "id", ssid])
        }
    }

    function disconnectFromNetwork(): void {
        const net = root.nativeNetworks.find(n => n.connected) ?? null
        if (net) net.disconnect()
    }

    function isNetworkSaved(ssid: string): bool {
        return root.savedNetworks.includes(ssid)
    }

    function getWifiStatus(): void {
        // Native Networking.wifiEnabled is already live; nothing to poll.
    }

    // ── nmcli helpers (password connect + saved profiles, kept per project rule) ─
    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: (code, status) => {
            if (QsSingletons.Flags.debug)
                console.log("[Network] rescan exited", code, status)
        }
    }

    Process {
        id: connectProc
        onExited: (code, status) => {
            if (code !== 0)
                root.connectionFailed("Connection failed (exit " + code + ")")
            checkSavedProc.running = true
        }
    }

    Process {
        id: checkSavedProc
        command: ["nmcli", "-g", "NAME", "connection", "show"]
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedNetworks = text.trim().split("\n").filter(n => n.length > 0)
                if (QsSingletons.Flags.debug)
                    console.log("[Network] saved networks:", root.savedNetworks.length)
            }
        }
    }

    Timer {
        interval: 10000
        running: root.pollingActive
        repeat: true
        onTriggered: checkSavedProc.running = true
    }
}
