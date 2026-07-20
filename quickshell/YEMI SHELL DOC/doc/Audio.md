# Audio

## 1. Component Overview

Audio is a service that manages audio volume and sink control for the Yemi QuickShell desktop. It provides volume adjustment, mute control, and sink selection capabilities consumed by the bar volume indicator and the pill mixer surface.

## 2. Project Structure and Dependencies

- **File**: `services/Audio.qml`
- **Imports**: `Quickshell`
- **Instantiated by**: `shell.qml` as `QsServices.Audio`
- **Depends on**: Quickshell audio/PipeWire integration

## 3. Component Hierarchy and Role

Audio is a service object that wraps Quickshell's audio backend. It exposes volume level, mute state, and available sinks for consumption by UI components.

## 4. Properties

Audio does not expose documented public properties in the source.

## 5. Signals

Audio does not define custom signals.

## 6. Methods

Audio does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: Initialized as a core service
- **Volume.qml**: Reads audio state for the bar volume indicator
- **Mixer.qml**: Reads audio state for the pill mixer surface

## 8. Usage Example

Audio is consumed by bar and pill components. Direct usage depends on the Quickshell audio API.
