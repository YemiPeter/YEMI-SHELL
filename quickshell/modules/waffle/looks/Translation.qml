pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

Singleton {
    id: root

    // Passthrough stub — returns the key string as-is.
    // Real i18n will replace this later; nothing to wire up in this pass.
    function tr(key) {
        return key;
    }
}