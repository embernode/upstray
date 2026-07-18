import QtQuick

// Small uppercase label introducing a group of rows.
Text {
    required property var theme

    color: theme.headingDevice
    font.family: theme.fontMono
    font.pixelSize: 11
    font.weight: Font.Bold
    font.letterSpacing: 0.8
    font.capitalization: Font.AllUppercase
}
