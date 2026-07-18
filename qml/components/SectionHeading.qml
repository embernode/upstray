import QtQuick

// Small uppercase label introducing a group of rows.
Text {
    property var theme

    color: theme ? theme.headingDevice : "#1ABC9C"
    font.family: theme ? theme.fontMono : "monospace"
    font.pixelSize: 11
    font.weight: Font.Bold
    font.letterSpacing: 0.8
    font.capitalization: Font.AllUppercase
}
