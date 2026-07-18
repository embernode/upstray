import QtQuick
import QtQuick.Controls

// Labelled text input.
Item {
    id: root

    required property var theme
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
        color: root.theme.textMuted
        font.family: root.theme.fontSans
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    TextField {
        id: field
        anchors.top: caption.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right

        color: root.theme.textPrimary
        placeholderTextColor: root.theme.textMuted
        font.family: root.theme.fontSans
        font.pixelSize: 13
        font.weight: Font.Medium

        leftPadding: 12
        rightPadding: 12
        topPadding: 11
        bottomPadding: 11

        background: Rectangle {
            radius: root.theme.radiusInput
            color: root.theme.sunken
            border.width: 1
            border.color: field.activeFocus
                ? root.theme.accent
                : root.theme.inputBorder

            Behavior on border.color { ColorAnimation { duration: 120 } }
        }
    }
}
