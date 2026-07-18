import QtQuick

// Restores window resizing, which a frameless window loses along with its
// system decoration. Each grip hands off to the compositor via
// startSystemResize so edge snapping and keyboard modifiers keep working.
Item {
    id: root

    property int thickness: 6

    anchors.fill: parent
    // Above the content, so the grips are reachable at the window border.
    z: 100

    component Grip: Item {
        property int edges: 0
        property int shape: Qt.SizeAllCursor

        HoverHandler {
            cursorShape: parent.shape
        }

        DragHandler {
            target: null
            onActiveChanged: if (active) root.Window.window.startSystemResize(parent.edges)
        }
    }

    Grip {
        edges: Qt.LeftEdge
        shape: Qt.SizeHorCursor
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom
                  topMargin: root.thickness; bottomMargin: root.thickness }
        width: root.thickness
    }

    Grip {
        edges: Qt.RightEdge
        shape: Qt.SizeHorCursor
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom
                  topMargin: root.thickness; bottomMargin: root.thickness }
        width: root.thickness
    }

    Grip {
        edges: Qt.TopEdge
        shape: Qt.SizeVerCursor
        anchors { top: parent.top; left: parent.left; right: parent.right
                  leftMargin: root.thickness; rightMargin: root.thickness }
        height: root.thickness
    }

    Grip {
        edges: Qt.BottomEdge
        shape: Qt.SizeVerCursor
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right
                  leftMargin: root.thickness; rightMargin: root.thickness }
        height: root.thickness
    }

    Grip {
        edges: Qt.TopEdge | Qt.LeftEdge
        shape: Qt.SizeFDiagCursor
        anchors { top: parent.top; left: parent.left }
        width: root.thickness; height: root.thickness
    }

    Grip {
        edges: Qt.TopEdge | Qt.RightEdge
        shape: Qt.SizeBDiagCursor
        anchors { top: parent.top; right: parent.right }
        width: root.thickness; height: root.thickness
    }

    Grip {
        edges: Qt.BottomEdge | Qt.LeftEdge
        shape: Qt.SizeBDiagCursor
        anchors { bottom: parent.bottom; left: parent.left }
        width: root.thickness; height: root.thickness
    }

    Grip {
        edges: Qt.BottomEdge | Qt.RightEdge
        shape: Qt.SizeFDiagCursor
        anchors { bottom: parent.bottom; right: parent.right }
        width: root.thickness; height: root.thickness
    }
}
