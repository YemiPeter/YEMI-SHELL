pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    id: root

    // Passthrough stub — returns the key string as-is.
    // Real i18n will replace this later; nothing to wire up in this pass.
    // Moved here from qs.modules.waffle.looks so shared services (Weather,
    // GlobalActions, deferred/*) can resolve it without coupling to Waffle.
    function tr(key) {
        return key;
    }
}
