# WifiGlyph

## 1. Component Overview

WifiGlyph is a pill component that displays a Wi-Fi signal strength icon for the Yemi QuickShell desktop. It renders a visual glyph representing the current Wi-Fi signal quality.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/WifiGlyph.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Link.qml` or other network-related components
- **Depends on**: Network service, Networking Quickshell integration

## 3. Component Hierarchy and Role

WifiGlyph is a reusable UI component that renders Wi-Fi signal strength as a visual icon. It is used within the Link surface and potentially other network-related components.

## 4. Properties

WifiGlyph does not expose documented public properties in the source.

## 5. Signals

WifiGlyph does not define custom signals.

## 6. Methods

WifiGlyph does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Link.qml**: Uses WifiGlyph to display Wi-Fi signal strength
- **Network service**: Reads Wi-Fi signal level

## 8. Usage Example

WifiGlyph is used as a child component within network-related surfaces.
