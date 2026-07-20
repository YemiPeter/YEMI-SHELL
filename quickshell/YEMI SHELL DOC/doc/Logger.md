# Logger

## 1. Component Overview

Logger is a service that provides structured logging for the Yemi QuickShell desktop. It centralizes log output from shell components, services, and IPC handlers, making it easier to debug shell behavior.

## 2. Project Structure and Dependencies

- **File**: `services/Logger.qml`
- **Imports**: `Quickshell`
- **Instantiated by**: `shell.qml` as `QsServices.Logger`
- **Depends on**: Quickshell logging integration

## 3. Component Hierarchy and Role

Logger is a service object that wraps Quickshell's logging backend. It exposes logging methods for different log levels and categories.

## 4. Properties

Logger does not expose documented public properties in the source.

## 5. Signals

Logger does not define custom signals.

## 6. Methods

Logger does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: Initialized as a core service
- **All services and components**: Use Logger for debug and error output

## 8. Usage Example

Logger is used throughout the shell for debug output. Direct usage depends on the Quickshell logging API.
