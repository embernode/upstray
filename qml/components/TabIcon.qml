import QtQuick
import QtQuick.Shapes

// Renders an SVG path from the design at icon size. Paths are authored against
// a 24x24 viewBox and scaled to whatever this item is sized to.
Item {
    id: root

    property string pathData: ""
    property color iconColor: "#7f8896"
    property bool filled: false
    property real strokeWidth: 2

    implicitWidth: 15
    implicitHeight: 15

    Shape {
        width: 24
        height: 24
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            xScale: root.width / 24
            yScale: root.height / 24
        }

        ShapePath {
            strokeColor: root.filled ? "transparent" : root.iconColor
            fillColor: root.filled ? root.iconColor : "transparent"
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.pathData }
        }
    }
}
