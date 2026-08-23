pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * Privacy indicator state.
 * - micActive: a physical input source is linked to a capture stream
 *   (mirrors Audio.micBeingAccessed via Pipewire link inspection).
 * - screenSharing: set by the UI (util/system buttons) — detection lives there,
 *   not in this service, matching the Waffle reference.
 */
Singleton {
    id: root

    property bool micActive: (Pipewire.links?.values ?? []).some(link =>
        link.source && !link.source.isStream && !link.source.isSink
            && link.target && link.target.isStream
    )

    property bool screenSharing: false
}
