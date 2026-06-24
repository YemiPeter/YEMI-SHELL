# Ricelin Launcher System Source Code Audit

Based on my analysis of the Ricelin launcher system, here is the complete audit and extraction of the launcher source code:

## FILE: [.Ricelin/configs/quickshell/launcher/Launcher.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/Launcher.qml)
```qml
import QtQuick
import QtQuick.Controls
import Quickshell

Item {
    id: box

    property var entries: []
    property int total: 0
    property int selectedIndex: 0

    signal launch(var entry)
    signal quit()

    width: 540
    implicitHeight: frame.implicitHeight

    readonly property color bgTop: Qt.rgba(43 / 255, 33 / 255, 28 / 255, 0.97)
    readonly property color bgBot: Qt.rgba(29 / 255, 18 / 255, 14 / 255, 0.97)
    readonly property color hair: Qt.rgba(150 / 255, 172 / 255, 212 / 255, 0.10)
    readonly property color verm: "#c0442b"
    readonly property color cream: "#e6d6cb"
    readonly property color dim: "#7e8794"
    readonly property color dim2: "#565e6a"

    function moveSelection(delta) {
        if (entries.length === 0) return;
        var n = selectedIndex + delta;
        if (n < 0) n = 0;
        if (n > entries.length - 1) n = entries.length - 1;
        selectedIndex = n;
        list.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function activate() {
        if (entries.length > 0 && selectedIndex >= 0 && selectedIndex < entries.length)
            box.launch(entries[selectedIndex]);
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: 22
        gradient: Gradient {
            GradientStop { position: 0.0; color: box.bgTop }
            GradientStop { position: 1.0; color: box.bgBot }
        }
        border.width: 1
        border.color: box.hair
        clip: true
        implicitHeight: input.height + list.implicitHeight

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Item {
            id: input
            width: parent.width
            height: 60

            Rectangle {
                id: dot
                anchors.verticalCenter: parent.verticalCenter
                x: 21
                width: 9
                height: 9
                radius: 4.5
                color: box.verm
            }

            TextField {
                id: field
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: dot.right
                anchors.leftMargin: 13
                anchors.right: counter.left
                anchors.rightMargin: 13
                background: null
                color: box.cream
                font.family: "Inter"
                font.pixelSize: 16
                placeholderText: "Search"
                placeholderTextColor: box.dim
                selectByMouse: true
                focus: true
                cursorDelegate: Rectangle {
                    width: 2
                    color: box.verm
                    visible: field.cursorVisible
                }
                Keys.onUpPressed: box.moveSelection(-1)
                Keys.onDownPressed: box.moveSelection(1)
                Keys.onPressed: (e) => {
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { box.activate(); e.accepted = true; }
                    else if (e.key === Qt.Key_Escape) { box.quit(); e.accepted = true; }
                }
            }

            Text {
                id: counter
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 21
                text: box.entries.length + " / " + box.total
                color: box.dim2
                font.family: "Inter"
                font.pixelSize: 11
            }
        }

        Rectangle {
            id: divider
            anchors.top: input.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            height: 1
            color: box.hair
        }

        ListView {
            id: list
            width: parent.width
            anchors.top: divider.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            leftMargin: 14
            rightMargin: 14
            topMargin: 8
            bottomMargin: 14
            spacing: 4
            implicitHeight: Math.min(contentHeight + topMargin + bottomMargin, 8 * 54 + topMargin + bottomMargin)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: box.entries.length

            delegate: AppRow {
                required property int index
                width: ListView.view.width - 28
                entry: box.entries[index]
                selected: index === box.selectedIndex
                onActivated: { box.selectedIndex = index; box.activate(); }
                onEntered: box.selectedIndex = index
            }
        }
    }

    function focusField() { field.forceActiveFocus(); }
    property alias query: field.text
}
```

## FILE: [.Ricelin/configs/quickshell/launcher/AppRow.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/AppRow.qml)
```qml
import QtQuick
import Quickshell

Item {
    id: row

    required property var entry
    property bool selected: false

    signal activated()
    signal entered()

    implicitHeight: 50

    readonly property color cream: "#e6d6cb"
    readonly property color white: "#fff6f0"
    readonly property color dim2: "#565e6a"

    readonly property string secondary: {
        if (entry.genericName && entry.genericName.length > 0) return entry.genericName;
        if (entry.categories && entry.categories.length > 0) {
            var first = String(entry.categories).split(";")[0].trim();
            if (first.length > 0) return first;
        }
        return "";
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#c0442b" }
            GradientStop { position: 1.0; color: "#a3371f" }
        }
        visible: row.selected
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: row.entered()
        onClicked: row.activated()
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15

        Rectangle {
            id: iconBox
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 26
            radius: 6
            color: Qt.rgba(1, 1, 1, 0.05)
            visible: !(icon.status === Image.Ready && icon.source !== "")
        }

        Image {
            id: icon
            anchors.fill: iconBox
            sourceSize.width: 52
            sourceSize.height: 52
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: status === Image.Ready && source !== ""
            source: row.entry.icon ? Quickshell.iconPath(row.entry.icon, true) : ""
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: icon.right
            anchors.leftMargin: 12
            text: row.entry.name
            color: row.selected ? row.white : row.cream
            font.family: "Inter"
            font.pixelSize: 15
            font.weight: row.selected ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
            width: Math.min(implicitWidth, parent.width - icon.width - 12 - secondary.width - enter.width - 18)
        }

        Text {
            id: enter
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            text: "↵"
            color: row.white
            font.family: "Inter"
            font.pixelSize: 13
            visible: row.selected
            width: visible ? implicitWidth + 7 : 0
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: secondary
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: enter.left
            text: row.secondary
            color: row.selected ? Qt.rgba(1, 0.965, 0.941, 0.72) : row.dim2
            font.family: "Inter"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
        }
    }
}
```

## FILE: [.Ricelin/configs/quickshell/launcher/shell.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/shell.qml)
```qml
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "lib/fuzzy.js" as Fuzzy

ShellRoot {
    id: root

    property string query: ""
    property var usage: ({})
    property bool shown: false
    property string targetMonitor: ""

    IpcHandler {
        target: "launcher"
        function show(mon: string): void {
            root.targetMonitor = mon;
            root.shown = true;
        }
        function hide(): void { root.shown = false; }
        function toggle(mon: string): void {
            if (root.shown) { root.shown = false; return; }
            root.targetMonitor = mon;
            root.shown = true;
        }
    }

    FileView {
        id: usageStore
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/ricelin/launcher-usage.json"
        blockLoading: true
        atomicWrites: true
        printErrors: false
    }

    Component.onCompleted: {
        var raw = usageStore.text();
        try {
            root.usage = raw && raw.length ? JSON.parse(raw) : ({});
        } catch (e) {
            root.usage = ({});
        }
    }

    readonly property var allEntries: {
        var src = DesktopEntries.applications.values;
        var out = [];
        for (var i = 0; i < src.length; i++)
            if (src[i] && !src[i].noDisplay) out.push(src[i]);
        return out;
    }

    readonly property int totalCount: allEntries.length
    readonly property var results: Fuzzy.rank(allEntries, query, usage)

    function run(entry) {
        if (entry) {
            if (entry.id) {
                root.usage[entry.id] = (root.usage[entry.id] || 0) + 1;
                usageStore.setText(JSON.stringify(root.usage));
                usageStore.waitForJob();
            }
            entry.execute();
        }
        root.shown = false;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: root.shown && root.targetMonitor === modelData.name

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "launcher"

            anchors { top: true; left: true; right: true; bottom: true }

            MouseArea {
                anchors.fill: parent
                onClicked: root.shown = false
            }

            Launcher {
                id: launcher
                anchors.centerIn: parent

                entries: root.results
                total: root.totalCount

                onLaunch: (entry) => root.run(entry)
                onQuit: root.shown = false
            }

            Connections {
                target: launcher
                function onQueryChanged() {
                    root.query = launcher.query;
                    launcher.selectedIndex = 0;
                }
            }

            onVisibleChanged: {
                if (visible) {
                    launcher.query = "";
                    launcher.selectedIndex = 0;
                    launcher.focusField();
                }
            }
        }
    }
}
```

## FILE: [.Ricelin/configs/quickshell/pill/Launcher.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Launcher.qml)
```qml
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "Singletons"
import "lib/fuzzy.js" as Fuzzy

/**
 * Launcher surface: search field over a ranked application list, drawn as one
 * of the pill's surfaces. Desktop entries are ranked by fuzzy match and prior
 * launch frequency (usage file shared with the standalone launcher), the
 * chosen entry executes directly.
 */
PillSurface {
    id: root

    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    property string query: ""
    property int selectedIndex: 0
    property var usage: ({})

    /**
     * Window-coordinate position of the last hover event that was allowed to
     * move the selection. Rows sliding under a stationary cursor during
     * keyboard scrolling produce hover events at an unchanged window position,
     * which must not steal the keyboard selection.
     */
    property point lastPointer: Qt.point(-1, -1)

    readonly property point caretPoint: {
        void root.width;
        void root.height;
        void search.input.width;
        return search.input.mapToItem(root,
            search.input.cursorRectangle.x + search.input.cursorRectangle.width / 2,
            search.input.cursorRectangle.y + search.input.cursorRectangle.height / 2);
    }
    readonly property real caretX: caretPoint.x
    readonly property real caretY: caretPoint.y

    ameForm: "caret"
    amePoint: Qt.point(caretX, caretY)

    readonly property string usageFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/ricelin/launcher-usage.json"

    readonly property var allEntries: {
        var src = DesktopEntries.applications.values;
        var out = [];
        for (var i = 0; i < src.length; i++)
            if (src[i] && !src[i].noDisplay) out.push(src[i]);
        return out;
    }
    readonly property int totalCount: allEntries.length
    readonly property var results: Fuzzy.rank(allEntries, query, usage)

    function focusField() { search.input.forceActiveFocus(); }

    function mapCategory(raw) {
        const order = [
            ["TerminalEmulator", "Terminal"], ["WebBrowser", "Browser"],
            ["InstantMessaging", "Chat"], ["Audio", "Media"], ["AudioVideo", "Media"],
            ["Video", "Media"], ["Game", "Game"], ["Development", "Dev"],
            ["Graphics", "Graphics"], ["Office", "Office"], ["Settings", "System"],
            ["System", "System"], ["Utility", "Tool"], ["Network", "Net"]
        ];
        const cats = String(raw).split(/[;,]/);
        for (let i = 0; i < order.length; i++)
            if (cats.includes(order[i][0]))
                return order[i][1];
        return "";
    }

    function move(delta) {
        if (results.length === 0)
            return;
        selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + delta));
        list.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function activate() {
        if (results.length === 0 || selectedIndex < 0 || selectedIndex >= results.length)
            return;
        var entry = results[selectedIndex];
        if (entry) {
            if (entry.id) {
                root.usage[entry.id] = (root.usage[entry.id] || 0) + 1;
                usageStore.setText(JSON.stringify(root.usage));
            }
            entry.execute();
        }
        root.requestClose();
    }

    onActiveChanged: {
        if (active) {
            query = "";
            search.text = "";
            selectedIndex = 0;
            Qt.callLater(root.focusField);
        }
    }
    onResultsChanged: if (selectedIndex >= results.length) selectedIndex = 0;

    FileView {
        id: usageStore
        path: root.usageFile
        blockLoading: true
        atomicWrites: true
        printErrors: false
    }

    Component.onCompleted: {
        var raw = usageStore.text();
        try {
            root.usage = raw && raw.length ? JSON.parse(raw) : ({});
        } catch (e) {
            root.usage = ({});
        }
    }

    SearchField {
        id: search
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        s: root.s
        kanji: "探"
        placeholder: "Search apps"
        counterText: root.results.length + " / " + root.totalCount
        onTextChanged: {
            root.query = text;
            root.selectedIndex = 0;
        }
        onMoved: (d) => root.move(d)
        onAccepted: root.activate()
        onDismissed: root.requestClose()
    }

    Rectangle {
        id: divider
        anchors.top: search.bottom
        anchors.topMargin: 8 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.hair
    }

    Text {
        anchors.centerIn: list
        visible: root.results.length === 0
        text: root.query.length ? "No matches" : "No apps found"
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 10.5 * root.s
    }

    ListView {
        id: list
        anchors.top: divider.bottom
        anchors.topMargin: 6 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 2 * root.s
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.results.length

        delegate: Item {
            id: appRow
            required property int index
            width: list.width
            height: 34 * root.s

            readonly property var entry: root.results[index]
            readonly property bool selected: index === root.selectedIndex

            readonly property string secondary: {
                if (!entry)
                    return "";
                if (entry.genericName && entry.genericName.length > 0)
                    return entry.genericName;
                if (entry.categories && entry.categories.length > 0)
                    return root.mapCategory(entry.categories);
                return "";
            }

            Rectangle {
                anchors.fill: parent
                radius: 9 * root.s
                visible: appRow.selected || rowArea.containsMouse
                color: appRow.selected ? Theme.frameBg : Qt.rgba(0.94, 0.88, 0.84, 0.03)
                border.width: appRow.selected ? 1 : 0
                border.color: Theme.frameBorder
            }

            MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: (m) => {
                    var g = rowArea.mapToItem(null, m.x, m.y);
                    if (g.x !== root.lastPointer.x || g.y !== root.lastPointer.y) {
                        root.lastPointer = Qt.point(g.x, g.y);
                        root.selectedIndex = appRow.index;
                    }
                }
                onClicked: {
                    root.selectedIndex = appRow.index;
                    root.activate();
                }
            }

            Item {
                anchors.fill: parent
                anchors.leftMargin: 11 * root.s
                anchors.rightMargin: 11 * root.s

                Rectangle {
                    id: iconBg
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20 * root.s
                    height: 20 * root.s
                    radius: 5 * root.s
                    color: Qt.rgba(1, 1, 1, 0.05)
                    visible: !(icon.status === Image.Ready && icon.source != "")
                }
                Image {
                    id: icon
                    anchors.fill: iconBg
                    sourceSize.width: Math.round(40 * root.s)
                    sourceSize.height: Math.round(40 * root.s)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    visible: status === Image.Ready && source != ""
                    source: appRow.entry && appRow.entry.icon ? Quickshell.iconPath(appRow.entry.icon, true) : ""
                }

                Text {
                    id: nameText
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: icon.right
                    anchors.leftMargin: 10 * root.s
                    text: appRow.entry ? appRow.entry.name : ""
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 13 * root.s
                    font.weight: appRow.selected ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, parent.width - icon.width - 10 * root.s - sec.width - ret.width - 12 * root.s)
                }
                TextMetrics {
                    id: retMetrics
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    text: "↵"
                }
                Text {
                    id: ret
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    text: retMetrics.text
                    color: Theme.vermLit
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    visible: appRow.selected
                    width: visible ? retMetrics.advanceWidth + 6 * root.s : 0
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    id: sec
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: ret.left
                    text: appRow.secondary
                    color: appRow.selected ? Theme.dim : Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 10.5 * root.s
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
```

## FILE: [.Ricelin/configs/quickshell/launcher/lib/fuzzy.js](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/lib/fuzzy.js)
```js
function haystacks(e) {
    var parts = [];
    if (e.name) parts.push(String(e.name));
    if (e.genericName) parts.push(String(e.genericName));
    if (e.keywords) for (var i = 0; i < e.keywords.length; i++) parts.push(String(e.keywords[i]));
    return parts;
}

function subsequence(needle, hay) {
    var j = 0;
    for (var i = 0; i < hay.length && j < needle.length; i++)
        if (hay[i] === needle[j]) j++;
    return j === needle.length;
}

function score(e, q) {
    var name = (e.name || "").toLowerCase();
    if (name.indexOf(q) === 0) return 0;
    var fields = haystacks(e);
    var best = 99;
    for (var i = 0; i < fields.length; i++) {
        var f = fields[i].toLowerCase();
        if (f.indexOf(q) !== -1) { best = Math.min(best, 1); continue; }
        if (subsequence(q, f)) best = Math.min(best, 2);
    }
    return best;
}

function uses(usage, e) {
    if (!usage || !e || !e.id) return 0;
    var c = usage[e.id];
    return typeof c === "number" ? c : 0;
}

function rank(entries, query, usage) {
    usage = usage || {};
    var visible = [];
    for (var i = 0; i < entries.length; i++)
        if (!entries[i].noDisplay) visible.push(entries[i]);

    var q = (query || "").trim().toLowerCase();
    if (q.length === 0)
        return visible.slice().sort(function (a, b) {
            var ua = uses(usage, a);
            var ub = uses(usage, b);
            if (ua !== ub) return ub - ua;
            return (a.name || "").toLowerCase().localeCompare((b.name || "").toLowerCase());
        });

    var scored = [];
    for (var k = 0; k < visible.length; k++) {
        var s = score(visible[k], q);
        if (s < 99) scored.push({ e: visible[k], s: s });
    }
    scored.sort(function (a, b) {
        if (a.s !== b.s) return a.s - b.s;
        var ua = uses(usage, a.e);
        var ub = uses(usage, b.e);
        if (ua !== ub) return ub - ua;
        return (a.e.name || "").toLowerCase().localeCompare((b.e.name || "").toLowerCase());
    });
    return scored.map(function (x) { return x.e; });
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { rank, score, subsequence };
}
```

## FILE: [.Ricelin/configs/quickshell/pill/SearchField.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/SearchField.qml)
```qml
import QtQuick
import QtQuick.Controls
import "Singletons"

Item {
    id: root

    property real s: 1
    property string kanji: ""
    property string placeholder: ""
    property string counterText: ""

    /**
     * Map Left/Right to the moved() signal instead of text-cursor motion. For a
     * horizontal result strip the arrows should page the strip; without this the
     * field swallows them until the caret sits at a text boundary, so navigation
     * stalls mid-query.
     */
    property bool horizontalNav: false
    readonly property alias input: field
    property alias text: field.text
    default property alias rightContent: rightSlot.data

    signal moved(int delta)
    signal accepted()
    signal dismissed()
    signal keyPressed(var event)

    height: 30 * s

    Text {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        visible: Flags.showGlyphs
        width: Flags.showGlyphs ? implicitWidth : 0
        text: root.kanji
        color: Theme.dim
        font.family: Theme.fontJp
        font.weight: Font.Medium
        font.pixelSize: 16 * root.s
    }

    TextField {
        id: field
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: glyph.right
        anchors.leftMargin: Flags.showGlyphs ? 10 * root.s : 0
        anchors.right: counter.left
        anchors.rightMargin: 10 * root.s
        background: null
        padding: 0
        color: Theme.cream
        font.family: Theme.font
        font.pixelSize: 15 * root.s
        placeholderText: root.placeholder
        placeholderTextColor: Theme.faint
        selectByMouse: true
        selectionColor: Theme.verm
        cursorDelegate: Item {}
        Keys.onUpPressed: root.moved(-1)
        Keys.onDownPressed: root.moved(1)
        Keys.onPressed: (e) => {
            root.keyPressed(e);
            if (e.accepted)
                return;
            if (root.horizontalNav && (e.key === Qt.Key_Left || e.key === Qt.Key_Right)) {
                root.moved(e.key === Qt.Key_Right ? 1 : -1);
                e.accepted = true;
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                root.accepted();
                e.accepted = true;
            } else if (e.key === Qt.Key_Escape) {
                root.dismissed();
                e.accepted = true;
            }
        }
    }

    Rectangle {
        anchors.left: field.left
        anchors.right: field.right
        anchors.top: field.bottom
        anchors.topMargin: 2 * root.s
        height: 1
        color: Theme.faint
        opacity: field.activeFocus ? 0.7 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard } }
    }

    Text {
        id: counter
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: rightSlot.left
        anchors.rightMargin: rightSlot.width > 0 ? 10 * root.s : 0
        text: root.counterText
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 10.5 * root.s
        font.features: { "tnum": 1 }
    }

    Item {
        id: rightSlot
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        width: childrenRect.width
        height: parent.height
    }
}
```

## FILE: [.Ricelin/configs/quickshell/pill/PillSurface.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/PillSurface.qml)
```qml
import QtQuick
import "Singletons"

/**
 * Shared morph-surface base for the pill's standard surfaces. Each surface fills
 * the pill body inset by its own margins (scaled by `s`), fades in with the morph
 * as it nears full openness, and is only enabled while open. The host sets `open`,
 * `s` and `morphCloseness`; the surface sets its own `mTop`/`mLeft`/`mRight`/
 * `mBottom` insets. `active` mirrors `open` for the older `onActiveChanged` hooks.
 * `requestClose()` asks the pill to dismiss. Osd and Toast use a different
 * lifecycle and do not derive from this base.
 */
Item {
    id: surface

    property real s: 1
    property bool open: false
    property real morphCloseness: 1

    property real mTop: 0
    property real mLeft: 0
    property real mRight: 0
    property real mBottom: 0

    signal requestClose()

    /**
     * Ame anchor. Each surface declares the flame's form and dock point (in
     * surface-local coords) for its open state; the host maps the point into
     * pill space and feeds the active surface's pair to Ame. Left non-readonly
     * so a deriving surface can re-bind. Base default is off at the centre.
     */
    property string ameForm: "off"
    property point amePoint: Qt.point(width / 2, height / 2)

    readonly property bool active: open

    anchors.fill: parent
    anchors.topMargin: mTop * s
    anchors.leftMargin: mLeft * s
    anchors.rightMargin: mRight * s
    anchors.bottomMargin: mBottom * s

    enabled: open
    opacity: open ? Math.pow(morphCloseness, 1.3) : 0
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard }
    }
}
```

## DEPENDENCY: DesktopEntries
- Type: external service
- Used by: [.Ricelin/configs/quickshell/launcher/shell.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/shell.qml), [.Ricelin/configs/quickshell/pill/Launcher.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Launcher.qml)
- Source: Quickshell framework
- Purpose: Provides access to installed application entries (.desktop files) for the launcher to display

## DEPENDENCY: ShellRoot
- Type: import
- Used by: [.Ricelin/configs/quickshell/launcher/shell.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/shell.qml)
- Source: Quickshell framework
- Purpose: Base component for shell applications

## DEPENDENCY: IpcHandler
- Type: import
- Used by: [.Ricelin/configs/quickshell/launcher/shell.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/shell.qml)
- Source: Quickshell framework
- Purpose: Handles inter-process communication for showing/hiding the launcher

## DEPENDENCY: PanelWindow
- Type: import
- Used by: [.Ricelin/configs/quickshell/launcher/shell.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/shell.qml)
- Source: Quickshell framework
- Purpose: Creates the overlay window for the launcher surface

## DEPENDENCY: WlrLayershell
- Type: import
- Used by: [.Ricelin/configs/quickshell/launcher/shell.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/shell.qml)
- Source: Quickshell framework
- Purpose: Manages the Wayland layer shell for the launcher window

## DEPENDENCY: FileView
- Type: import
- Used by: [.Ricelin/configs/quickshell/launcher/shell.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/shell.qml), [.Ricelin/configs/quickshell/pill/Launcher.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Launcher.qml)
- Source: Quickshell framework
- Purpose: Reads/writes the usage statistics file for app ranking

## DEPENDENCY: Quickshell.iconPath
- Type: external service
- Used by: [.Ricelin/configs/quickshell/launcher/AppRow.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/AppRow.qml), [.Ricelin/configs/quickshell/pill/Launcher.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Launcher.qml)
- Source: Quickshell framework
- Purpose: Resolves application icon paths

## DEPENDENCY: Theme
- Type: custom component
- Used by: [.Ricelin/configs/quickshell/pill/Launcher.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Launcher.qml), [.Ricelin/configs/quickshell/pill/SearchField.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/SearchField.qml)
- Source: [.Ricelin/configs/quickshell/pill/Singletons/Theme.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Singletons/Theme.qml)
- Purpose: Provides theming properties (colors, fonts) for the launcher UI

## DEPENDENCY: Dyn
- Type: custom component
- Used by: [.Ricelin/configs/quickshell/pill/Singletons/Theme.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Singletons/Theme.qml)
- Source: [.Ricelin/configs/quickshell/pill/Singletons/Dyn.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Singletons/Dyn.qml)
- Purpose: Provides dynamic theming based on wallpaper colors

## DEPENDENCY: Flags
- Type: custom component
- Used by: [.Ricelin/configs/quickshell/pill/Launcher.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Launcher.qml), [.Ricelin/configs/quickshell/pill/SearchField.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/SearchField.qml), [.Ricelin/configs/quickshell/pill/Singletons/Theme.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Singletons/Theme.qml)
- Source: [.Ricelin/configs/quickshell/pill/Singletons/Flags.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Singletons/Flags.qml)
- Purpose: Provides session flags and user preferences

## DEPENDENCY: Motion
- Type: custom component
- Used by: [.Ricelin/configs/quickshell/pill/SearchField.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/SearchField.qml)
- Source: [.Ricelin/configs/quickshell/pill/Singletons/Motion.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Singletons/Motion.qml)
- Purpose: Provides animation timing and easing properties

## DEPENDENCY: fuzzy.js
- Type: custom component
- Used by: [.Ricelin/configs/quickshell/launcher/shell.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/shell.qml), [.Ricelin/configs/quickshell/pill/Launcher.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Launcher.qml)
- Source: [.Ricelin/configs/quickshell/launcher/lib/fuzzy.js](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/lib/fuzzy.js)
- Purpose: Implements fuzzy search and ranking algorithm for app entries

## ENTRY POINT ANALYSIS:
The launcher system has two entry points:
1. **Standalone launcher**: [.Ricelin/configs/quickshell/launcher/shell.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/launcher/shell.qml) - This creates a PanelWindow that covers the entire screen and centers the Launcher component. It's controlled via IPC calls (show/hide/toggle functions).

2. **Pill launcher**: [.Ricelin/configs/quickshell/pill/Launcher.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/Launcher.qml) - This integrates into the pill system as a surface that can be opened/closed from the main pill interface.

Both launchers use the same fuzzy search algorithm and share the same usage statistics file to maintain consistent app rankings.