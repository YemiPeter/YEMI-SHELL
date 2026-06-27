import QtQuick
import QtQuick.Shapes
import "Singletons"

/**
 * Self-contained vector glyph drawn from baked SVG path data, so the pill never
 * depends on the system icon theme or external asset files. Set `name` to pick a
 * glyph, `color` to tint it; stroked glyphs use `stroke` width, filled glyphs
 * (media transport) paint solid. Paths live in a 24x24 space and scale to the
 * item's size. Each glyph's actual bounding box is centred within the item on
 * both axes, so glyphs with differing path extents share one optical baseline.
 */
Item {
    id: root

    property string name: ""
    property color color: Theme.iconDim
    property real stroke: 1.8
    property real fillProgress: 1

    readonly property real u: Math.min(width, height) / 24

    readonly property var glyphs: ({
        "sun": { d: "M16 12a4 4 0 1 0-8 0a4 4 0 1 0 8 0 M12 2v2 M12 20v2 M4.2 4.2l1.4 1.4 M18.4 18.4l1.4 1.4 M2 12h2 M20 12h2 M4.2 19.8l1.4-1.4 M18.4 5.6l1.4-1.4", fill: false },
        "moon": { d: "M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9z", fill: false },
        "cloud": { d: "M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9z", fill: false },
        "cloud-rain": { d: "M4 14.9A7 7 0 1 1 15.7 8h1.8a4.5 4.5 0 0 1 2.5 8.2 M16 14v5 M8 14v5 M12 16v5", fill: false },
        "cloud-snow": { d: "M4 14.9A7 7 0 1 1 15.7 8h1.8a4.5 4.5 0 0 1 2.5 8.2 M8 15h.01 M8 19h.01 M12 17h.01 M12 21h.01 M16 15h.01 M16 19h.01", fill: false },
        "cloud-lightning": { d: "M6 16.3A7 7 0 1 1 15.7 8h1.8a4.5 4.5 0 0 1 .5 9 M12 12l-3 5h4l-3 5", fill: false },
        "cloud-fog": { d: "M4 14.9A7 7 0 1 1 15.7 8h1.8a4.5 4.5 0 0 1 2.5 8.2 M16 17H7 M17 21H9", fill: false },
        "droplet": { d: "M12 3c3.5 4.2 5.5 7 5.5 9.5a5.5 5.5 0 0 1-11 0C6.5 10 8.5 7.2 12 3z", fill: false },
        "check": { d: "M20 6 9 17l-5-5", fill: false },
        "arrow-up": { d: "M12 19V5 M6 11l6-6 6 6", fill: false },
        "stopwatch": { d: "M10 2h4 M12 14V9 M19 7l1.5-1.5 M12 22a8 8 0 1 0 0-16 8 8 0 0 0 0 16z", fill: false },
        "type": { d: "M4 7V5h16v2 M12 5v14 M9 19h6", fill: false },
        "language": { d: "M3 5h8 M7 4v2c0 3.5-2 6-4 7 M4 9c0 2 2.5 4 6 4.5 M13 20l4-9 4 9 M14.5 17h5", fill: false },
        "palette": { d: "M12 2a10 10 0 1 0 0 20c1.1 0 2-.9 2-2v-1a2 2 0 0 1 2-2h1c1.1 0 2-.9 2-2a10 10 0 0 0-9-11z M7.5 11.5a1 1 0 1 0 .01 0 M9.5 7.5a1 1 0 1 0 .01 0 M14 6.5a1 1 0 1 0 .01 0 M17 10.5a1 1 0 1 0 .01 0", fill: false },
        "scaling": { d: "M3 7V3h4 M17 3h4v4 M21 17v4h-4 M7 21H3v-4 M9 12h6", fill: false },
        "waves": { d: "M2 8c2.5-3 5-3 7.5 0s5 3 7.5 0 M2 16c2.5-3 5-3 7.5 0s5 3 7.5 0", fill: false },
        "sparkles": { d: "M12 3l1.7 5.1 5.1 1.7-5.1 1.7L12 16.6l-1.7-5.1-5.1-1.7 5.1-1.7z M5 15.5l.7 2 2 .7-2 .7-.7 2-.7-2-2-.7 2-.7z", fill: false },
        "app-window": { d: "M3 5h18a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z M2 9.5h20 M5.5 7h.01 M8 7h.01 M10.5 7h.01", fill: false },
        "mouse": { d: "M12 2a6 6 0 0 0-6 6v8a6 6 0 0 0 12 0V8a6 6 0 0 0-6-6z M12 6v3.5", fill: false },
        "keyboard": { d: "M2.5 6h19a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1h-19a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1z M6 10h.01 M10 10h.01 M14 10h.01 M18 10h.01 M7.5 14h9", fill: false },
        "download": { d: "M12 3v12 M7.5 10.5l4.5 4.5 4.5-4.5 M5 21h14", fill: false },
        "monitor": { d: "M4 4h16a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-16a2 2 0 0 1-2-2v-9a2 2 0 0 1 2-2z M8 21h8 M12 17v4 M7 13c1.5-4 3-4 5-1s3.5 2 5-2", fill: false },
        "speaker": { d: "M4 9v6h4l5 4V5L8 9z M16 9.5a3 3 0 0 1 0 5 M18.5 7.5a6 6 0 0 1 0 9", fill: false },
        "speaker-off": { d: "M4 9v6h4l5 4V5L8 9z M16.2 9.8l4.4 4.4 M20.6 9.8l-4.4 4.4", fill: false },
        "mic": { d: "M9 9V6a3 3 0 0 1 6 0v6a3 3 0 0 1-6 0 M5 11a7 7 0 0 0 14 0 M12 18v3", fill: false },
        "mic-off": { d: "M9 9V6a3 3 0 0 1 6 0v3 M15 12v0a3 3 0 0 1-5.6 1.5 M5 11a7 7 0 0 0 11 5.5 M12 19v3 M3 3l18 18", fill: false },
        "lock": { d: "M6 10h12a1.5 1.5 0 0 1 1.5 1.5v6a1.5 1.5 0 0 1-1.5 1.5H6a1.5 1.5 0 0 1-1.5-1.5v-6A1.5 1.5 0 0 1 6 10z M8.5 10V7a3.5 3.5 0 0 1 7 0v3", fill: false },
        "lock-round": { d: "M8 8.5H16A3 3 0 0 1 19 11.5V15.5A3 3 0 0 1 16 18.5H8A3 3 0 0 1 5 15.5V11.5A3 3 0 0 1 8 8.5Z M8.4 8.5V5.7A3.6 3.6 0 0 1 15.6 5.7V8.5", fill: false },
        "lock-outline": { d: "M6.4 9.5H17.6A2.4 2.4 0 0 1 20 11.9V17.6A2.4 2.4 0 0 1 17.6 20H6.4A2.4 2.4 0 0 1 4 17.6V11.9A2.4 2.4 0 0 1 6.4 9.5Z M7.5 9.5V6A4.5 4.5 0 0 1 16.5 6V9.5", fill: false },
        "logout": { d: "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4 M16 17l5-5-5-5 M21 12H9", fill: false },
        "suspend": { d: "M21 12.8A9 9 0 1 1 11.2 3 7 7 0 0 0 21 12.8z", fill: false },
        "reboot": { d: "M21 12a9 9 0 1 1-2.6-6.4 M21 3v5h-5", fill: false },
        "shutdown": { d: "M12 3v9 M7.8 6.3a8 8 0 1 0 8.4 0", fill: false },
        "mixer": { d: "M6 4v16M12 4v16M18 4v16M3.5 9h5M9.5 15h5M15.5 7h5", fill: false },
        "music": { d: "M9 18V5l12-2v13 M9 18a3 3 0 1 1-6 0 3 3 0 0 1 6 0z M21 16a3 3 0 1 1-6 0 3 3 0 0 1 6 0z", fill: false },
        "play": { d: "M7 5l12 7-12 7z", fill: true },
        "pause": { d: "M8 5h3v14H8z M13 5h3v14h-3z", fill: true },
        "skip-back": { d: "M6 5v14 M6 19l-4-4 4-4 M18 5v14 M18 19l4-4-4-4", fill: false },
        "skip-forward": { d: "M6 5v14 M6 19l-4-4 4-4 M18 5v14 M18 19l4-4-4-4", fill: false },
        "chevron-left": { d: "M15 18l-6-6 6-6", fill: false },
        "chevron-right": { d: "M9 18l6-6-6-6", fill: false },
        "chevron-up": { d: "M18 15l-6-6-6 6", fill: false },
        "chevron-down": { d: "M6 9l6 6 6-6", fill: false },
        "clock": { d: "M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z M12 6v6l4 2", fill: false },
        "inbox": { d: "M22 12h-6l-2 3h-4l-2-3H2l2.5 9h19L22 12z M2 12l2-6h16l2 6", fill: false },
        "cog": { d: "M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z", fill: false },
        "video": { d: "M23 7l-7 5 7 5V7z M1 5h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H1a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2z", fill: false },
        "image": { d: "M19 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2z M8.5 10a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z M21 15l-5-5L5 21", fill: false },
        "folder": { d: "M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z", fill: false },
        "trash": { d: "M3 6h18 M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2 M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6", fill: false },
        "copy": { d: "M8 4v12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V7.72a2 2 0 0 0-.59-1.42l-3.58-3.58A2 2 0 0 0 14.28 2H10a2 2 0 0 0-2 2z M16 2v4a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h4", fill: false },
        "settings": { d: "M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z", fill: false }
    })

    readonly property var glyph: glyphs[name] || glyphs["circle"]

    implicitWidth: 24 * u
    implicitHeight: 24 * u

    Shape {
        id: shape
        width: 24
        height: 24
        scale: root.u
        transformOrigin: Item.TopLeft
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.glyph.fill ? "transparent" : root.color
            fillColor: root.glyph.fill ? Qt.alpha(root.color, root.fillProgress) : "transparent"
            strokeWidth: (root.stroke / root.u)
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.glyph.d }
        }
    }
}
