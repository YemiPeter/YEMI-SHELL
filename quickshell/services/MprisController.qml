pragma Singleton
import QtQuick
import qs.services

QtObject {
    id: root

    readonly property alias activePlayer: Players.active
    readonly property alias canChangeVolume: Players.active ? Players.active.canChangeVolume : false
    readonly property alias canGoNext: Players.active ? Players.active.canGoNext : false
    readonly property alias canGoPrevious: Players.active ? Players.active.canGoPrevious : false
    readonly property bool isYtMusicActive: false

    function getVolume() {
        return Players.active ? Players.active.volume : 0;
    }

    function setVolume(volume) {
        if (Players.active) {
            Players.active.volume = volume;
        }
    }

    function next() {
        if (Players.active) {
            Players.active.next();
        }
    }

    function previous() {
        if (Players.active) {
            Players.active.previous();
        }
    }

    function togglePlaying() {
        if (Players.active) {
            Players.active.togglePlaying();
        }
    }

    function getIdentity(player) {
        return Players.getIdentity(player);
    }
}
