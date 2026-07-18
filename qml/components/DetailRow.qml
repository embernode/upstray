import QtQuick

// One label/value pair inside a Card. Rows are separated by a hairline; the
// last row in a group omits it.
Item {
    id: root

    property var theme
    property string label: ""
    property string value: "—"
    property bool last: false

    implicitHeight: 44

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.theme ? root.theme.textMuted : "#8a919b"
        font.family: root.theme ? root.theme.fontSans : "sans-serif"
        font.pixelSize: 13
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: root.theme ? root.theme.textPrimary : "#e7eaee"
        font.family: root.theme ? root.theme.fontMono : "monospace"
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
        color: root.theme ? root.theme.divider : "transparent"
    }
}
