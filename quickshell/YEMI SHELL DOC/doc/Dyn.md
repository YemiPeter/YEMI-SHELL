# Dyn

## 1. Component Overview

Dyn is a singleton that provides dynamic values for the Yemi QuickShell desktop. It exposes values that change over time or in response to system events, such as time, date, or other dynamic state.

## 2. Project Structure and Dependencies

- **File**: `singletons/Dyn.qml`
- **Imports**: `QtQuick`
- **Instantiated by**: Components that need dynamic values (e.g., clock components)
- **Depends on**: No external dependencies

## 3. Component Hierarchy and Role

Dyn is a `Singleton` extending `QtObject`. It exposes properties that update dynamically, such as current time and date, for consumption by UI components.

## 4. Properties

Dyn does not expose documented public properties in the source.

## 5. Signals

Dyn does not define custom signals.

## 6. Methods

Dyn does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Clock components**: Read dynamic time/date values
- **Calendar surface**: May read date values for calendar rendering

## 8. Usage Example

Dyn is consumed by clock and calendar components. Direct usage depends on the properties exposed by the singleton.
