import QtQuick

// Raised surface that groups related content.
Rectangle {
    property var theme

    radius: theme ? theme.radiusCard : 12
    color: theme ? theme.surface : "transparent"
    border.width: 1
    border.color: theme ? theme.border : "transparent"
}
