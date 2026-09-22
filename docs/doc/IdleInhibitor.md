# IdleInhibitor

## 1. Component Overview

IdleInhibitor is a service that prevents the system from entering idle/sleep state when certain applications or conditions require it. It is used by the shell to inhibit idle during fullscreen video, presentations, or other activities that should not be interrupted.

## 2. Project Structure and Dependencies

- **File**: `services/IdleInhibitor.qml`
- **Imports**: `Quickshell`
- **Instantiated by**: `shell.qml` as `QsServices.IdleInhibitor`
- **Depends on**: Quickshell idle inhibition integration

## 3. Component Hierarchy and Role

IdleInhibitor is a service object that wraps Quickshell's idle inhibition backend. It exposes methods to request and release idle inhibition.

## 4. Properties

IdleInhibitor does not expose documented public properties in the source.

## 5. Signals

IdleInhibitor does not define custom signals.

## 6. Methods

IdleInhibitor does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: Initialized as a core service
- **Fullscreen detection**: May trigger idle inhibition when fullscreen is active

## 8. Usage Example

IdleInhibitor is used internally by the shell. Direct usage depends on the Quickshell idle inhibition API.
