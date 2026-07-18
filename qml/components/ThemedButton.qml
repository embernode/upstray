import QtQuick

// Tinted action button. Sits on an accent wash rather than a solid fill, so it
// reads as secondary to the data it acts on.
Rectangle {
    id: root

    property var theme
    property string label: ""
    property string iconPath: ""

    signal clicked()

    readonly property color _accent: theme ? theme.accent : "#5cc8ff"

    implicitWidth: content.implicitWidth + 32
    implicitHeight: 36
    radius: theme ? theme.radiusInput : 9

    color: Qt.rgba(_accent.r, _accent.g, _accent.b, hover.hovered ? 0.20 : 0.12)
    border.width: 1
    border.color: Qt.rgba(_accent.r, _accent.g, _accent.b, 0.35)

    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 7

        TabIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.iconPath.length > 0
            width: 14
            height: 14
            pathData: root.iconPath
            iconColor: root._accent
            strokeWidth: 1.8
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root._accent
            font.family: root.theme ? root.theme.fontSans : "sans-serif"
            font.pixelSize: 13
            font.weight: Font.Bold
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.clicked()
    }
}
