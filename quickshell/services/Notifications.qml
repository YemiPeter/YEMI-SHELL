pragma Singleton
import QtQuick
import qs.services

QtObject {
    id: root

    readonly property var notifications: Notifs.notifications
    readonly property var popupList: Notifs.activeNotifications
    readonly property bool silent: Notifs.silent
    readonly property var appNameList: {
        const names = [];
        for (const n of Notifs.notifications) {
            if (names.indexOf(n.appName) === -1) names.push(n.appName);
        }
        return names;
    }
    readonly property var groupsByAppName: Notifs.groupedNotifications
    readonly property var popupAppNameList: {
        const names = [];
        for (const n of Notifs.activeNotifications) {
            if (names.indexOf(n.appName) === -1) names.push(n.appName);
        }
        return names;
    }
    readonly property var popupGroupsByAppName: {
        const groups = {};
        for (const n of Notifs.activeNotifications) {
            const key = n.appName || "Unknown";
            if (!groups[key]) groups[key] = [];
            groups[key].push(n);
        }
        return groups;
    }
    readonly property var list: Notifs.notifications

    function discardAllNotifications() {
        Notifs.clearAll();
    }

    function discardNotification(notification) {
        Notifs.deleteNotification(notification);
    }

    function attemptInvokeAction(notification, actionId) {
        if (notification && notification.actions && notification.actions[actionId]) {
            notification.actions[actionId].trigger();
        }
    }

    function cancelTimeout(notification) {
        // No-op for waffle port
    }

    function ensureInitialized() {
        // No-op for waffle port
    }
}
