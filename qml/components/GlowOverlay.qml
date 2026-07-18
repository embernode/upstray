import QtQuick
import QtQuick.Shapes

// Ambient wash of the current state colour bleeding down from the top of the
// window, behind the title bar and hero. Purely decorative — it sits under the
// content and never intercepts input.
//
// The origin sits above the top edge so the visible band is the gradient's
// outer, gentler region rather than its hot centre, and the falloff is stepped
// across several stops so it eases into the window colour instead of ending on
// a visible edge.
Item {
    id: root

    property color glowColor: "#2ecc71"
    property real intensity: 0.10
    // Fraction of item height; negative places the origin above the top edge.
    property real originY: -0.55
    // Radius as a multiple of item width.
    property real spread: 1.40

    function _at(stop) {
        return Qt.rgba(glowColor.r, glowColor.g, glowColor.b, intensity * stop)
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: root.width / 2
                centerY: root.height * root.originY
                centerRadius: root.width * root.spread
                focalX: root.width / 2
                focalY: root.height * root.originY

                GradientStop { position: 0.00; color: root._at(1.00) }
                GradientStop { position: 0.30; color: root._at(0.72) }
                GradientStop { position: 0.50; color: root._at(0.42) }
                GradientStop { position: 0.70; color: root._at(0.18) }
                GradientStop { position: 0.85; color: root._at(0.06) }
                GradientStop { position: 1.00; color: root._at(0.00) }
            }

            startX: 0; startY: 0
            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0;          y: root.height }
            PathLine { x: 0;          y: 0 }
        }
    }

    Behavior on glowColor {
        ColorAnimation { duration: 400 }
    }
}
