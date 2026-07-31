// Dummy Module type for qs namespace module
// This file exists to make `import qs` succeed when no sub-imports are used
pragma Singleton
import QtQuick 2.0

Item {
    // Empty singleton - qs module exists for namespace purposes
    // Use `import qs.services` or `import qs.modules.common` for actual types
}