pragma Singleton
import QtQuick
import qs.services

QtObject {
    id: root

    readonly property alias notifications: Notifs.notifications
    readonly property alias popupList: Notifs.activeNotifications
    readonly property alias silent: Notifs.silent
    readonly property alias appNameList: Notifs.appNameList
    readonly property alias groupsByAppName: Notifs.groupsByAppName
    readonly property alias popupAppNameList: Notifs.popupAppNameList
    readonly property alias popupGroupsByAppName: Notifs.popupGroupsByAppName

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
