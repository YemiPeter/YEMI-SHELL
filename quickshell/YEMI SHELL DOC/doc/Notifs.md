# Notifs

## 1. Component Overview

Notifs is a singleton notification service for the Yemi QuickShell desktop. It manages the lifecycle of notifications received from the D-Bus NotificationServer, including DND filtering, grouping by application, history retention, and periodic cleanup. It exposes active notifications, recent history, grouped views, and per-app counts for consumption by notification popups and the notification center.

## 2. Project Structure and Dependencies

- **File**: `services/Notifs.qml`
- **Imports**: `QtQuick 6.10`, `Quickshell`, `Quickshell.Services.Notifications`
- **Instantiated by**: `shell.qml` as `QsServices.Notifs`
- **Depends on**: Quickshell `Notif` type from `Quickshell.Services.Notifications`

## 3. Component Hierarchy and Role

Notifs is a `Singleton` extending `QtObject`. It holds a list of `Notif` wrapper objects and exposes derived properties for active notifications, recent history, grouped notifications, and counts. It also contains a `Timer` for periodic cleanup of old notifications and a `component Notif` that wraps the raw Quickshell `Notif` into a richer object with timestamp, closed state, and formatted time string.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| notifications | list<Notif> | [] | No | All notifications currently in memory |
| activeNotifications | list<Notif> | derived | No | Read-only; notifications where `closed` is false |
| maxNotifications | int | 100 | No | Maximum number of notifications to keep in memory |
| recentNotifications | list<Notif> | derived | No | Read-only; notifications from the past 24 hours, sorted newest first |
| groupedNotifications | var | derived | No | Read-only; notifications grouped by `appName` |
| notificationCounts | var | derived | No | Read-only; count of notifications per app |
| dnd | bool | false | No | Whether do-not-disturb mode is active |
| silent | bool | alias for dnd | No | iNiR compatibility alias for DND state |
| count | int | alias for _notifCount | No | iNiR compatibility alias for active notification count |
| _notifCount | int | derived | No | Read-only; count of active notifications |

## 5. Signals

Notifs does not define custom signals.

## 6. Methods

#### addNotification(notif) : void
Wraps the incoming Quickshell `Notif` in a `Notif` component, applies DND filtering (suppresses non-urgent notifications when DND is active), and prepends it to the `notifications` list, capped at `maxNotifications`.

#### toggleDnd() : void
Toggles the `dnd` property.

#### clearAll() : void
Closes all active notifications by calling `close()` on each.

#### clearApp(appName) : void
Closes all active notifications from the specified application.

## 7. Inter-Component Interactions

- **shell.qml**: `NotificationServer.onNotification` calls `notifs.addNotification(notif)` for every incoming D-Bus notification
- **Notif component**: Wraps the raw Quickshell `Notif` and mirrors its properties (`summary`, `body`, `appName`, `appIcon`, `image`, `urgency`, `actions`) through `Connections` bindings
- **Notification popups**: Read `activeNotifications` and `groupedNotifications` to render popups
- **Notification center**: Read `recentNotifications` for history view

## 8. Usage Example

```qml
import "../../services" as QsServices

// Check if DND is active
if (QsServices.Notifs.dnd) {
  console.log("Do not disturb is on")
}

// Get active notifications
const active = QsServices.Notifs.activeNotifications

// Clear all notifications
QsServices.Notifs.clearAll()
```
