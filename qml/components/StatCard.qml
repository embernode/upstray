import QtQuick

// Small labelled figure on a surface tile. Used for the metric grid.
Rectangle {
    id: root

    required property var theme
    property string caption: ""
    property string value: "—"
    property color valueColor: theme.textPrimary

    radius: theme.radiusCard
    color: theme.surface
    border.width: 1
    border.color: theme.border
    implicitHeight: content.implicitHeight + 28

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 8

        Text {
            text: root.caption
            color: root.theme.textMuted
            font.family: root.theme.fontMono
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 0.5
            font.capitalization: Font.AllUppercase
            elide: Text.ElideRight
            width: parent.width
        }

        Text {
            text: root.value
            color: root.valueColor
            font.family: root.theme.fontMono
            font.pixelSize: 17
            font.weight: Font.Bold
            elide: Text.ElideRight
            width: parent.width
        }
    }
}
