import QtQuick
import QtQuick.Layouts

// Top band of the window: charge ring alongside status, detail line and runtime.
Item {
    id: root

    required property var theme
    property real chargePct: -1
    property string statusText: ""
    property string detailText: ""
    property string runtimeText: "—"
    property color stateColor: theme.online
    // Pulses the status dot while the UPS is not on utility power.
    property bool alert: false

    // Derived from the layout's own content height. The layout must NOT be
    // anchored to the bottom as well, or its height comes from this item while
    // this item's height comes from the layout — circular, and it makes
    // Layout.alignment centring unreliable.
    implicitHeight: layout.implicitHeight + 26 + 22

    FontMetrics {
        id: runtimeMetrics
        font: runtimeValue.font
    }

    RowLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.topMargin: 26
        spacing: 20

        ChargeRing {
            theme: root.theme
            value: root.chargePct
            ringColor: root.stateColor
            Layout.preferredWidth: 104
            Layout.preferredHeight: 104
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Rectangle {
                Layout.preferredHeight: 26
                Layout.preferredWidth: pill.implicitWidth + 22
                Layout.bottomMargin: 11
                radius: root.theme.radiusPill
                color: root.theme.soft(root.stateColor)

                Row {
                    id: pill
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8; height: 8; radius: 4
                        color: root.stateColor

                        SequentialAnimation on opacity {
                            running: root.alert
                            loops: Animation.Infinite
                            alwaysRunToEnd: true
                            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutQuad }
                        }
                        // The animation leaves opacity wherever it stopped.
                        onOpacityChanged: if (!root.alert && opacity !== 1.0) opacity = 1.0
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.statusText
                        color: root.stateColor
                        font.family: root.theme.fontSans
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.letterSpacing: 0.3
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 14
                text: root.detailText
                color: root.theme.textSecondary
                font.family: root.theme.fontSans
                font.pixelSize: 13
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
            }

            Row {
                spacing: 8
                // The runtime figure is digits, which have no descenders, so its
                // line box carries empty space underneath. Left in, that space
                // is counted when the column is vertically centred against the
                // ring and pushes the visible text noticeably high.
                Layout.preferredHeight: implicitHeight - runtimeMetrics.descent

                Text {
                    id: runtimeValue
                    text: root.runtimeText
                    color: root.theme.textPrimary
                    font.family: root.theme.fontSans
                    font.pixelSize: 30
                    font.weight: Font.ExtraBold
                }

                Text {
                    id: caption
                    // The small label sits on the figure's baseline, not the
                    // other way round: anchoring the large text to the small
                    // one drags it above its own row box by the difference in
                    // ascent, which then reads as a vertical misalignment
                    // against the charge ring.
                    anchors.baseline: runtimeValue.baseline
                    text: "runtime left"
                    color: root.theme.textMuted
                    font.family: root.theme.fontMono
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
