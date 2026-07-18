import QtQuick
import QtQuick.Shapes

// Direction-of-power indicator between two cells of the flow strip.
// Drawn rather than a glyph so the weight matches the rest of the UI.
//
// The glyph is centred in the item and the item is wider than the glyph, so it
// keeps clear air either side of the neighbouring cell dividers.
Item {
    id: root

    property color arrowColor: "#2ecc71"
    readonly property real _span: 20
    readonly property real _x0: (width - _span) / 2
    readonly property real _x1: _x0 + _span

    implicitWidth: 46
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

            startX: root._x0; startY: root.height / 2
            PathLine { x: root._x1; y: root.height / 2 }
        }

        ShapePath {
            strokeColor: root.arrowColor
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            startX: root._x1 - 6; startY: root.height / 2 - 5
            PathLine { x: root._x1; y: root.height / 2 }
            PathLine { x: root._x1 - 6; y: root.height / 2 + 5 }
        }
    }

    Behavior on arrowColor {
        ColorAnimation { duration: 250 }
    }
}
