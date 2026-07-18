import QtQuick
import QtQuick.Controls

// Tinted action button. Sits on an accent wash rather than a solid fill, so it
// reads as secondary to the data it acts on.
//
// Built on Button rather than a bare Rectangle so it keeps tab focus,
// space/return activation and accessibility metadata.
Button {
    id: root

    required property var theme
    property string iconPath: ""

    readonly property color _accent: theme.accent

    focusPolicy: Qt.StrongFocus
    activeFocusOnTab: true

    leftPadding: 16
    rightPadding: 16
    topPadding: 0
    bottomPadding: 0
    implicitHeight: 36

    Accessible.role: Accessible.Button
    Accessible.name: root.text

    background: Rectangle {
        radius: root.theme.radiusInput
        color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b,
                       root.down ? 0.26 : root.hovered ? 0.20 : 0.12)
        border.width: 1
        border.color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b,
                              root.visualFocus ? 0.90 : 0.35)

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    contentItem: Row {
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
            text: root.text
            color: root._accent
            font.family: root.theme.fontSans
            font.pixelSize: 13
            font.weight: Font.Bold
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
