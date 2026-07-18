import QtQuick

// One label/value pair inside a Card. Rows are separated by a hairline; the
// last row in a group omits it.
Item {
    id: root

    required property var theme
    property string label: ""
    property string value: "—"
    property bool last: false

    implicitHeight: 44

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.theme.textMuted
        font.family: root.theme.fontSans
        font.pixelSize: 13
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: root.theme.textPrimary
        font.family: root.theme.fontMono
        font.pixelSize: 13
        font.weight: Font.Bold
        elide: Text.ElideRight
        // Never let a long value collide with its label.
        width: Math.min(implicitWidth, root.width * 0.62)
        horizontalAlignment: Text.AlignRight
    }

    Rectangle {
        visible: !root.last
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: root.theme.divider
    }
}
