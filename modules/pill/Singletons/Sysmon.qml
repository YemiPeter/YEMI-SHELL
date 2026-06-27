pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * System-vitals backend for the sysmon surface. Polls CPU, memory, swap,
 * network, disk and (when a discrete GPU is present) GPU load, temperature and
 * VRAM, exposing them as live properties the surface binds to. Polling only runs
 * while `open` is true, on three decoupled cadences so a slow source never
 * stalls the dials: the cheap /proc and hwmon reads refresh every 500ms, the GPU
 * query every 1s, and disk plus uptime every 5s. Opening the surface primes all
 * three at once so the dials are populated immediately.
 *
 * CPU load is a two-sample delta of /proc/stat (busy vs total jiffies); network
 * rates are a two-sample delta of /proc/net/dev summed over every interface but
 * loopback, divided by the fast interval. CPU temperature resolves once to the
 * most accurate hwmon sensor available: AMD Tdie, else Intel "Package id 0",
 * else AMD Tctl, else the first temp1_input. The GPU path resolves once to
 * nvidia (nvidia-smi), AMD (sysfs gpu_busy_percent) or none; an Intel-only or
 * GPU-less machine reports `hasGpu` false so the surface drops to two dials and
 * hides the VRAM cell. Disk is the root filesystem's used percent.
 */
Singleton {
    id: root

    property bool open: false

    property int cpu: 0
    property int cpuTemp: -1

    property bool hasGpu: false
    property string gpuVendor: ""
    property string amdDev: ""
    property int gpu: 0
    property int gpuTemp: -1
    property bool hasVram: false
    property real vramUsedGb: 0
    property real vramTotalGb: 0

    property real memUsedGb: 0
    property real memTotalGb: 0
    property int memPct: 0
    property real swapUsedGb: 0

    property real netDown: 0
    property real netUp: 0

    property int diskPct: 0
    property string uptime: ""

    property string tempPath: ""

    property real prevCpuTotal: 0
    property real prevCpuIdle: 0
    property real prevRx: 0
    property real prevTx: 0
    property real prevNetTime: 0

    function primeAll() {
        if (tempPath.length === 0 || gpuVendor.length === 0) {
            detectProc.running = true;
            return;
        }
        prevCpuTotal = 0;
        prevRx = 0;
        prevNetTime = 0;
        fastTimer.running = true;
        if (hasGpu)
            gpuTimer.running = true;
        slowTimer.running = true;
    }

    onOpenChanged: if (open) primeAll()

    function fmtUptime(sec) {
        var d = Math.floor(sec / 86400);
        var h = Math.floor((sec % 86400) / 3600);
        var m = Math.floor((sec % 3600) / 60);
        var hh = h < 10 ? "0" + h : "" + h;
        var mm = m < 10 ? "0" + m : "" + m;
        return d > 0 ? d + "d " + hh + ":" + mm : hh + ":" + mm;
    }

    // --- Detection (runs once) ---
    Process {
        id: detectProc
        command: ["bash", "-c",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/sysmon-detect.sh"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var j = JSON.parse(text);
                    root.tempPath = j.tempPath || "";
                    root.gpuVendor = j.gpuVendor || "";
                    root.amdDev = j.amdDev || "";
                    root.hasGpu = j.hasGpu || false;
                    root.hasVram = j.hasVram || false;
                } catch (e) { /* ignore */ }
                primeAll();
            }
        }
    }

    // --- Fast poll: CPU, memory, temp (500ms) ---
    Timer {
        id: fastTimer
        interval: 500
        running: root.open
        repeat: true
        onTriggered: {
            // CPU from /proc/stat
            var cpuText = fileRead("/proc/stat");
            var lines = cpuText.split("\n");
            for (var i = 0; i < lines.length; i++) {
                if (lines[i].indexOf("cpu ") === 0) {
                    var parts = lines[i].split(/\s+/);
                    var total = 0, idle = 0;
                    for (var j = 1; j < parts.length; j++) {
                        var v = parseInt(parts[j]) || 0;
                        total += v;
                        if (j === 4) idle = v;
                    }
                    if (root.prevCpuTotal > 0) {
                        var dt = total - root.prevCpuTotal;
                        var di = idle - root.prevCpuIdle;
                        root.cpu = dt > 0 ? Math.round((1 - di / dt) * 100) : 0;
                    }
                    root.prevCpuTotal = total;
                    root.prevCpuIdle = idle;
                    break;
                }
            }

            // Memory from /proc/meminfo
            var memText = fileRead("/proc/meminfo");
            var memLines = memText.split("\n");
            var memTotal = 0, memAvail = 0, swapTotal = 0, swapFree = 0;
            for (var k = 0; k < memLines.length; k++) {
                if (memLines[k].indexOf("MemTotal:") === 0) memTotal = parseInt(memLines[k].split(/\s+/)[1]) || 0;
                if (memLines[k].indexOf("MemAvailable:") === 0) memAvail = parseInt(memLines[k].split(/\s+/)[1]) || 0;
                if (memLines[k].indexOf("SwapTotal:") === 0) swapTotal = parseInt(memLines[k].split(/\s+/)[1]) || 0;
                if (memLines[k].indexOf("SwapFree:") === 0) swapFree = parseInt(memLines[k].split(/\s+/)[1]) || 0;
            }
            root.memTotalGb = memTotal / 1048576;
            root.memUsedGb = (memTotal - memAvail) / 1048576;
            root.memPct = memTotal > 0 ? Math.round((1 - memAvail / memTotal) * 100) : 0;
            root.swapUsedGb = (swapTotal - swapFree) / 1048576;

            // Temperature
            if (root.tempPath.length > 0) {
                var tempText = fileRead(root.tempPath);
                root.cpuTemp = parseInt(tempText) || -1;
            }
        }
    }

    // --- GPU poll (1s) ---
    Process {
        id: nvidiaProc
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(/\s*,\s*/);
                if (parts.length >= 3) {
                    root.gpu = parseInt(parts[0]) || 0;
                    root.vramUsedGb = (parseFloat(parts[1]) || 0) / 1024;
                    root.vramTotalGb = (parseFloat(parts[2]) || 0) / 1024;
                }
            }
        }
    }

    Timer {
        id: gpuTimer
        interval: 1000
        running: root.open && root.hasGpu
        repeat: true
        onTriggered: {
            if (root.gpuVendor === "nvidia") {
                nvidiaProc.running = true;
            } else if (root.gpuVendor === "amd" && root.amdDev.length > 0) {
                var gpuBusy = fileRead("/sys/class/drm/" + root.amdDev + "/device/gpu_busy_percent");
                root.gpu = parseInt(gpuBusy) || 0;
            }
        }
    }

    // --- Slow poll: disk, uptime, network (5s) ---
    Timer {
        id: slowTimer
        interval: 5000
        running: root.open
        repeat: true
        onTriggered: {
            // Disk
            var stat = fileRead("/proc/stat");
            // uptime
            var upText = fileRead("/proc/uptime");
            root.uptime = fmtUptime(parseFloat(upText) || 0);

            // Network delta
            var netText = fileRead("/proc/net/dev");
            var netLines = netText.split("\n");
            var rx = 0, tx = 0;
            for (var i = 2; i < netLines.length; i++) {
                if (netLines[i].indexOf(":") > 0 && netLines[i].indexOf("lo:") !== 0) {
                    var parts = netLines[i].split(/\s+/);
                    rx += parseInt(parts[1]) || 0;
                    tx += parseInt(parts[9]) || 0;
                }
            }
            var now = Date.now();
            if (root.prevNetTime > 0) {
                var dt = (now - root.prevNetTime) / 1000;
                root.netDown = dt > 0 ? Math.round((rx - root.prevRx) / dt / 1024) : 0;
                root.netUp = dt > 0 ? Math.round((tx - root.prevTx) / dt / 1024) : 0;
            }
            root.prevRx = rx;
            root.prevTx = tx;
            root.prevNetTime = now;
        }
    }

    FileView {
        id: fileReader
        blockLoading: true
        printErrors: false
    }

    function fileRead(path) {
        fileReader.path = path;
        return fileReader.text();
    }
}

