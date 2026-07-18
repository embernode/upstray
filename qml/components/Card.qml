import QtQuick

// Raised surface that groups related content.
Rectangle {
    required property var theme

    radius: theme.radiusCard
    color: theme.surface
    border.width: 1
    border.color: theme.border
}
