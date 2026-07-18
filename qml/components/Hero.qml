import QtQuick
import QtQuick.Layouts

// Top band of the window: charge ring alongside status, detail line and runtime.
Item {
    id: root

    property var theme
    property real chargePct: -1
    property string statusText: ""
    property string detailText: ""
    property string runtimeText: "—"
    property color stateColor: theme ? theme.online : "#2ecc71"
    // Pulses the status dot while the UPS is not on utility power.
    property bool alert: false

    implicitHeight: layout.implicitHeight + 48

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.topMargin: 26
        anchors.bottomMargin: 22
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
                radius: root.theme ? root.theme.radiusPill : 20
                color: root.theme ? root.theme.soft(root.stateColor) : "transparent"

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
                        font.family: root.theme ? root.theme.fontSans : "sans-serif"
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
                color: root.theme ? root.theme.textSecondary : "#aeb4bd"
                font.family: root.theme ? root.theme.fontSans : "sans-serif"
                font.pixelSize: 13
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
                lineHeight: 1.25
            }

            Row {
                spacing: 8

                Text {
                    anchors.baseline: caption.baseline
                    text: root.runtimeText
                    color: root.theme ? root.theme.textPrimary : "#e7eaee"
                    font.family: root.theme ? root.theme.fontSans : "sans-serif"
                    font.pixelSize: 30
                    font.weight: Font.ExtraBold
                }

                Text {
                    id: caption
                    text: "runtime left"
                    color: root.theme ? root.theme.textMuted : "#7f8896"
                    font.family: root.theme ? root.theme.fontMono : "monospace"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
