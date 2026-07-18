import QtQuick
import QtQuick.Shapes

// In-window title bar for the frameless shell: mark, name, active device, and
// the two window controls. Dragging anywhere on the bar moves the window.
Item {
    id: root

    required property var theme
    property string deviceName: ""

    signal minimiseRequested()
    signal closeRequested()

    implicitHeight: 42

    // Drag-to-move. Handing off to the compositor keeps snapping and
    // multi-monitor behaviour working, which manual position maths would not.
    // No CanTakeOverFromAnything: that licenses this handler to steal the grab
    // from the window buttons, so a press-and-jiggle on close would drag the
    // window instead of activating the button.
    DragHandler {
        target: null
        onActiveChanged: if (active) root.Window.window.startSystemMove()
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 9

        Image {
            anchors.verticalCenter: parent.verticalCenter
            source: "qrc:/qt/qml/com/upstray/app/resources/icons/upstray.svg"
            sourceSize.width: 19
            sourceSize.height: 19
            width: 19
            height: 19
            smooth: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "UpsTray"
            color: root.theme.textTitle
            font.family: root.theme.fontSans
            font.pixelSize: 13
            // The design says 700, but Qt renders Manrope's bold weight heavier
            // than the browser does, so matching the number overshoots the look.
            font.weight: Font.Medium
            font.letterSpacing: 0.3
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.deviceName.length > 0
            text: "· " + root.deviceName
            color: root.theme.textMuted
            font.family: root.theme.fontMono
            font.pixelSize: 12
            font.weight: Font.Medium
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.width * 0.35)
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        component WindowButton: Rectangle {
            id: btn
            property string pathData: ""
            // Tests the variant: a white wash is invisible against a light
            // title bar, so the light theme needs a dark one instead.
            property color hoverBackground: !root.theme.dark ? Qt.rgba(0, 0, 0, 0.07)
                                                             : Qt.rgba(1, 1, 1, 0.07)
            property color hoverForeground: root.theme.textPrimary
            signal activated()

            width: 26; height: 26
            radius: 7
            color: hover.hovered ? hoverBackground : "transparent"

            Shape {
                anchors.centerIn: parent
                width: 12; height: 12
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: hover.hovered ? btn.hoverForeground
                                               : root.theme.textMuted
                    strokeWidth: 1.5
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: btn.pathData }
                }
            }

            HoverHandler { id: hover }
            TapHandler { onTapped: btn.activated() }
        }

        WindowButton {
            pathData: "M2 9 L10 9"
            onActivated: root.minimiseRequested()
        }

        WindowButton {
            pathData: "M3 3 L9 9 M9 3 L3 9"
            hoverBackground: root.theme.lowBattery
            hoverForeground: "#ffffff"
            onActivated: root.closeRequested()
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: root.theme.divider
    }
}
