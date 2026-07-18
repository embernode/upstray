import QtQuick
import QtQuick.Shapes

// Ambient wash of the current state colour bleeding down from the top of the
// window, behind the title bar and hero. Purely decorative — it sits under the
// content and never intercepts input.
Item {
    id: root

    property color glowColor: "#2ecc71"
    property real intensity: 0.22

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: root.width / 2
                centerY: 0
                centerRadius: root.width * 0.85
                focalX: root.width / 2
                focalY: 0

                GradientStop {
                    position: 0.0
                    color: Qt.rgba(root.glowColor.r, root.glowColor.g,
                                   root.glowColor.b, root.intensity)
                }
                GradientStop {
                    position: 0.7
                    color: Qt.rgba(root.glowColor.r, root.glowColor.g,
                                   root.glowColor.b, 0.0)
                }
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
