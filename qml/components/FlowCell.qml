import QtQuick

// One stage of the power-flow strip: a caption over a figure.
Item {
    id: root

    required property var theme
    property string caption: ""
    property string value: "—"
    property color valueColor: theme.textPrimary
    // The middle stage is fenced off from its neighbours.
    property bool showDividers: false

    Column {
        anchors.centerIn: parent
        spacing: 7

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.caption
            color: root.theme.textMuted
            font.family: root.theme.fontMono
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
            font.capitalization: Font.AllUppercase
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.value
            color: root.valueColor
            font.family: root.theme.fontMono
            font.pixelSize: 18
            font.weight: Font.Bold

            Behavior on color {
                ColorAnimation { duration: 250 }
            }
        }
    }

    Rectangle {
        visible: root.showDividers
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: root.theme.divider
    }

    Rectangle {
        visible: root.showDividers
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: root.theme.divider
    }
}
