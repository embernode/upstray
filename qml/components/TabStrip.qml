import QtQuick

// Tab selector: icon and label per tab, with an accent underline on the active
// one and a hairline separating the strip from the content below.
//
// `currentIndex` is the handle the tray menu uses to jump straight to Settings,
// so it must stay readable and writable from outside.
Item {
    id: root

    property var theme
    property int currentIndex: 0

    implicitHeight: 45

    readonly property var _tabs: [
        {
            label: qsTr("Monitor"),
            path: "M4 13a8 8 0 0 1 16 0 M12 13l4-3",
            filled: false
        },
        {
            label: qsTr("Details"),
            path: "M4 12h4v8h-4z M10 7h4v13h-4z M16 4h4v16h-4z",
            filled: true
        },
        {
            label: qsTr("Settings"),
            path: "M13 2 4 14h6l-1 8 9-12h-6l1-8z",
            filled: true
        }
    ]

    Row {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 2

        Repeater {
            model: root._tabs

            delegate: Item {
                id: tab
                required property int index
                required property var modelData

                width: (root.width - 32 - 4) / 3
                height: root.height

                readonly property bool active: root.currentIndex === tab.index
                readonly property color tint: tab.active
                    ? (root.theme ? root.theme.textPrimary : "#e7eaee")
                    : (root.theme ? root.theme.textMuted : "#7f8896")

                Row {
                    anchors.centerIn: parent
                    spacing: 7

                    TabIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        pathData: tab.modelData.path
                        filled: tab.modelData.filled
                        iconColor: tab.tint
                        Behavior on iconColor { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.modelData.label
                        color: tab.tint
                        font.family: root.theme ? root.theme.fontSans : "sans-serif"
                        // The design specifies 12.5px; pixelSize is an int, so
                        // this rounds up rather than silently failing to apply.
                        font.pixelSize: 13
                        font.weight: tab.active ? Font.Bold : Font.DemiBold
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    height: 2
                    radius: 2
                    color: tab.active ? (root.theme ? root.theme.accent : "#5cc8ff") : "transparent"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentIndex = tab.index
                }
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: root.theme ? root.theme.divider : "transparent"
    }
}
