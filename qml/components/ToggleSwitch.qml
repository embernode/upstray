import QtQuick
import QtQuick.Controls

// On/off control.
//
// Built on AbstractButton rather than a bare Item so it keeps tab focus,
// space/return activation and accessibility metadata. A hand-rolled Item with
// only a TapHandler has none of those and is mouse-only.
//
// `checkable` is false deliberately: `checked` stays a one-way binding from the
// backend, so the control asks for a change and repaints when the backend
// confirms it, rather than toggling itself and drifting from the stored value.
AbstractButton {
    id: root

    required property var theme
    signal toggleRequested()

    checkable: false
    focusPolicy: Qt.StrongFocus
    activeFocusOnTab: true
    padding: 0

    implicitWidth: 44
    implicitHeight: 24

    Accessible.role: Accessible.CheckBox
    Accessible.checked: root.checked

    onClicked: root.toggleRequested()

    background: Rectangle {
        radius: height / 2
        color: root.checked ? root.theme.accent : root.theme.inputBorder

        Behavior on color { ColorAnimation { duration: 150 } }

        // Focus ring, so a keyboard user can see where they are.
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: height / 2
            color: "transparent"
            border.width: 2
            border.color: root.theme.accent
            visible: root.visualFocus
        }
    }

    indicator: Rectangle {
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
}
