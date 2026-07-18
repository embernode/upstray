import QtQuick
import QtQuick.Controls

// Labelled text input.
Item {
    id: root

    property var theme
    property string label: ""
    property alias text: field.text
    property alias placeholder: field.placeholderText
    property alias inputHints: field.inputMethodHints
    property alias validator: field.validator

    implicitHeight: caption.implicitHeight + 6 + field.implicitHeight

    Text {
        id: caption
        anchors.top: parent.top
        anchors.left: parent.left
        text: root.label
        color: root.theme ? root.theme.textMuted : "#8a919b"
        font.family: root.theme ? root.theme.fontSans : "sans-serif"
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    TextField {
        id: field
        anchors.top: caption.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right

        color: root.theme ? root.theme.textPrimary : "#e7eaee"
        placeholderTextColor: root.theme ? root.theme.textMuted : "#7f8896"
        font.family: root.theme ? root.theme.fontSans : "sans-serif"
        font.pixelSize: 13
        font.weight: Font.Medium

        leftPadding: 12
        rightPadding: 12
        topPadding: 11
        bottomPadding: 11

        background: Rectangle {
            radius: root.theme ? root.theme.radiusInput : 9
            color: root.theme ? root.theme.sunken : "#0c0e12"
            border.width: 1
            border.color: field.activeFocus
                ? (root.theme ? root.theme.accent : "#5cc8ff")
                : (root.theme ? root.theme.inputBorder : "#2a3038")

            Behavior on border.color { ColorAnimation { duration: 120 } }
        }
    }
}
