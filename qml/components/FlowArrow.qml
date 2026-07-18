import QtQuick
import QtQuick.Shapes

// Direction-of-power indicator between two cells of the flow strip.
// Drawn rather than a glyph so the weight matches the rest of the UI.
Item {
    id: root

    property color arrowColor: "#2ecc71"

    implicitWidth: 30
    implicitHeight: 18

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.arrowColor
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            startX: 2; startY: root.height / 2
            PathLine { x: 22; y: root.height / 2 }
        }

        ShapePath {
            strokeColor: root.arrowColor
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            startX: 16; startY: root.height / 2 - 5
            PathLine { x: 22; y: root.height / 2 }
            PathLine { x: 16; y: root.height / 2 + 5 }
        }
    }

    Behavior on arrowColor {
        ColorAnimation { duration: 250 }
    }
}
