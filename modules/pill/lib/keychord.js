/**
 * Key chord capture for the keybinds surface.
 * Handles multi-key sequences like Super+Shift+K.
 */

class KeyChord {
    constructor() {
        this.listening = false;
        this.pressed = [];
        this.chord = "";
        this.timeout = null;
    }

    start() {
        this.listening = true;
        this.pressed = [];
        this.chord = "";
    }

    stop() {
        this.listening = false;
        this.pressed = [];
        this.chord = "";
        if (this.timeout) {
            clearTimeout(this.timeout);
            this.timeout = null;
        }
    }

    keyPress(key) {
        if (!this.listening) return;
        this.pressed.push(key);
        this.chord = this.pressed.join("+");
        // Auto-complete after 2s of inactivity
        if (this.timeout) clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
            this.listening = false;
            this.pressed = [];
        }, 2000);
    }

    keyRelease(key) {
        const idx = this.pressed.indexOf(key);
        if (idx >= 0) this.pressed.splice(idx, 1);
        if (this.pressed.length === 0 && this.timeout) {
            clearTimeout(this.timeout);
            this.timeout = null;
        }
    }
}
