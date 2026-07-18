import QtQuick

// On/off control. `checked` stays a one-way binding from the backend — the
// control asks for a change and repaints when the backend confirms it, rather
// than mutating its own state and drifting from the stored setting.
Item {
    id: root

    property var theme
    property bool checked: false
    signal toggleRequested()

    implicitWidth: 44
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? (root.theme ? root.theme.accent : "#5cc8ff")
                            : (root.theme ? root.theme.inputBorder : "#2a3038")

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Rectangle {
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        width: 18
        height: 18
        radius: 9
        color: "#ffffff"

        Behavior on x {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.toggleRequested()
    }
}
