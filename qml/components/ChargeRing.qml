import QtQuick
import QtQuick.Shapes

// Circular charge gauge. Sweeps clockwise from twelve o'clock.
// `value` is a percentage; negative means unknown, which draws track only.
Item {
    id: root

    required property var theme
    property real value: -1
    property color ringColor: "#2ecc71"
    property string caption: "charge"

    implicitWidth: 104
    implicitHeight: 104

    readonly property bool known: value >= 0
    readonly property real _radius: Math.max(0, Math.min(width, height) / 2 - strokeWidth / 2)
    readonly property real strokeWidth: 8

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.theme.track
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root._radius
                radiusY: root._radius
                startAngle: -90
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: root.ringColor
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root._radius
                radiusY: root._radius
                startAngle: -90
                sweepAngle: root.known ? Math.max(0, Math.min(100, root.value)) / 100 * 360 : 0

                Behavior on sweepAngle {
                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 3

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.known ? Math.round(root.value) + "%" : "—"
            color: root.ringColor
            font.family: root.theme.fontSans
            font.pixelSize: 26
            font.weight: Font.ExtraBold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.caption
            color: root.theme.textMuted
            font.family: root.theme.fontMono
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8
            font.capitalization: Font.AllUppercase
        }
    }
}
