pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Live weather for the pill's hover glance, served by Open-Meteo with no API key.
 * Location resolves once and is cached so a restart never re-hits the network for
 * coordinates: by default the city, latitude and longitude come from a keyless IP
 * lookup (ip-api), but a non-empty `Flags.weatherCity` override geocodes that name
 * via Open-Meteo's geocoder instead. Once coordinates are known the forecast runs
 * immediately and then every 20 minutes, exposing the current conditions plus a
 * 24-hour hourly strip.
 *
 * Everything is async through `Process` + `curl`, mirroring how Sysmon and Devices
 * fetch, so startup never blocks on a slow or absent connection. Every JSON parse
 * is guarded: a partial body or network blip leaves the last good values in place
 * and `ready` simply stays false until the first clean fetch lands.
 *
 * Conditions render as on-brand kanji rather than icons — 晴 clear, 曇 cloud,
 * 雨 rain, 雪 snow, 霧 fog, 雷 thunder, 月 a clear night — keyed off the WMO weather
 * code via `glyphFor`, with `labelFor` giving the short english word.
 */
Singleton {
    id: root

    // ADAPTED: ricelin → quickshell
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell"

    property int tempNow: 0
    property int codeNow: 0
    property int humidity: 0
    property bool isDay: true
    property string city: ""
    property var hourly: []
    property var daily: []
    property bool ready: false

    property real lat: 0
    property real lon: 0
    property bool located: false

    /**
     * Maps a WMO weather code to its on-brand kanji. Clear skies show 月 at night
     * so the glance reads day-versus-night at a glance; every other condition is
     * the same glyph round the clock.
     */
    function glyphFor(code, day) {
        if (code === 0) return day ? "sun" : "moon";
        if (code <= 3) return "cloud";
        if (code === 45 || code === 48) return "cloud-fog";
        if (code >= 95) return "cloud-lightning";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "cloud-snow";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "cloud-rain";
        return "cloud";
    }

    /** Short english word for a WMO weather code, for labels and accessibility. */
    function labelFor(code) {
        if (code === 0) return "Clear";
        if (code <= 3) return "Cloudy";
        if (code === 45 || code === 48) return "Fog";
        if (code >= 95) return "Thunder";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "Snow";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "Rain";
        return "Cloudy";
    }

    /** Persist resolved coordinates so a restart skips the location round-trip. */
    function cachePath() { return cacheDir + "/weather.json"; }

    function saveCache() {
        cacheWriter.path = cachePath();
        cacheWriter.text = JSON.stringify({ lat: lat, lon: lon, city: city });
        cacheWriter.atomicWrites = true;
    }

    function loadCache() {
        cacheReader.path = cachePath();
        try {
            var j = JSON.parse(cacheReader.text());
            if (j && j.lat && j.lon) {
                lat = j.lat; lon = j.lon; city = j.city || "";
                located = true;
            }
        } catch (e) { /* ignore */ }
    }

    function locate() {
        if (Flags.weatherCity.length > 0) {
            geoProc.running = true;
        } else {
            ipProc.running = true;
        }
    }

    function fetchWeather() {
        if (!located) return;
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat
            + "&longitude=" + lon
            + "&current=temperature_2m,relative_humidity_2m,weather_code,is_day"
            + "&hourly=temperature_2m,weather_code"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + "&timezone=auto&forecast_days=1";
        weatherProc.command = ["curl", "-s", url];
        weatherProc.running = true;
    }

    // --- Cache I/O ---
    FileView {
        id: cacheReader
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: cacheWriter
        atomicWrites: true
    }

    // --- Geocode via city name ---
    Process {
        id: geoProc
        command: ["curl", "-s",
            "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(Flags.weatherCity) + "&count=1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var j = JSON.parse(text);
                    if (j.results && j.results.length > 0) {
                        root.lat = j.results[0].latitude;
                        root.lon = j.results[0].longitude;
                        root.city = j.results[0].name;
                        root.located = true;
                        saveCache();
                        fetchWeather();
                    }
                } catch (e) { /* ignore */ }
            }
        }
    }

    // --- IP-based location lookup ---
    Process {
        id: ipProc
        command: ["curl", "-s", "http://ip-api.com/json/"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var j = JSON.parse(text);
                    if (j.lat && j.lon) {
                        root.lat = j.lat;
                        root.lon = j.lon;
                        root.city = j.city || "";
                        root.located = true;
                        saveCache();
                        fetchWeather();
                    }
                } catch (e) { /* ignore */ }
            }
        }
    }

    // --- Weather fetch ---
    Process {
        id: weatherProc
        command: ["curl", "-s", ""] // placeholder — fetchWeather() sets the actual URL
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var j = JSON.parse(text);
                    var c = j.current;
                    root.tempNow = Math.round(c.temperature_2m);
                    root.codeNow = c.weather_code;
                    root.humidity = c.relative_humidity_2m;
                    root.isDay = c.is_day === 1;
                    root.hourly = j.hourly.time.map(function(t, i) {
                        return { time: t, temp: Math.round(j.hourly.temperature_2m[i]), code: j.hourly.weather_code[i] };
                    });
                    root.daily = j.daily.time.map(function(t, i) {
                        return { time: t, code: j.daily.weather_code[i], max: Math.round(j.daily.temperature_2m_max[i]), min: Math.round(j.daily.temperature_2m_min[i]) };
                    });
                    root.ready = true;
                } catch (e) { /* ignore */ }
            }
        }
    }

    Timer {
        id: weatherTimer
        interval: 20 * 60 * 1000 // 20 minutes
        running: located
        repeat: true
        onTriggered: fetchWeather()
    }

    Component.onCompleted: {
        loadCache();
        if (located) fetchWeather();
        else locate();
    }
}