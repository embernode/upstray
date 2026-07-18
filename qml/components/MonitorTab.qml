import QtQuick
import QtQuick.Layouts

// Live power view: where power is flowing, how hard the UPS is working, and
// the three figures worth watching while it does.
Item {
    id: root

    required property var theme
    property color stateColor: theme.online
    // False while on battery — dims the utility-side arrow and reddens the input.
    property bool mainsPresent: true
    property bool connected: true

    property string inputVoltage: "—"
    property string outputVoltage: "—"
    property string loadPercentage: "—"
    property string powerWatts: "—"
    property string temperature: "—"
    property string frequency: "—"
    property string health: ""
    property real loadPct: -1

    readonly property color _idle: Qt.rgba(theme.textMuted.r, theme.textMuted.g,
                                           theme.textMuted.b, 0.45)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 16

        // ---- power flow strip ----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 74
            radius: root.theme.radiusCard
            color: root.theme.surface
            border.width: 1
            border.color: root.theme.border

            RowLayout {
                anchors.fill: parent
                spacing: 0

                FlowCell {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    theme: root.theme
                    caption: qsTr("Utility in")
                    value: root.inputVoltage
                    // Input reads red once mains is gone, not merely grey.
                    valueColor: !root.connected ? root.theme.textMuted
                              : root.mainsPresent  ? root.stateColor
                                                : root.theme.lowBattery
                }

                FlowArrow {
                    Layout.alignment: Qt.AlignVCenter
                    arrowColor: root.connected && root.mainsPresent ? root.stateColor : root._idle
                }

                FlowCell {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    theme: root.theme
                    caption: qsTr("Load")
                    value: root.loadPercentage
                    showDividers: true
                    valueColor: root.connected ? root.stateColor
                                               : root.theme.textMuted
                }

                FlowArrow {
                    Layout.alignment: Qt.AlignVCenter
                    arrowColor: root.connected ? root.stateColor : root._idle
                }

                FlowCell {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    theme: root.theme
                    caption: qsTr("Output")
                    value: root.outputVoltage
                }
            }
        }

        // ---- load bar ----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 74
            radius: root.theme.radiusCard
            color: root.theme.surface
            border.width: 1
            border.color: root.theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Load")
                        color: root.theme.textSecondary
                        font.family: root.theme.fontSans
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.powerWatts === "—" ? root.loadPercentage
                                                      : root.loadPercentage + " · " + root.powerWatts
                        color: root.theme.textPrimary
                        font.family: root.theme.fontMono
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: 5
                    color: root.theme.track

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        width: root.loadPct >= 0 ? parent.width * Math.min(100, root.loadPct) / 100 : 0
                        visible: width > 0

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.theme.online }
                            GradientStop { position: 1.0; color: root.theme.accent }
                        }

                        Behavior on width {
                            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }

        // ---- metric grid ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            StatCard {
                Layout.fillWidth: true
                theme: root.theme
                caption: qsTr("Temp")
                value: root.temperature
            }

            StatCard {
                Layout.fillWidth: true
                theme: root.theme
                caption: qsTr("Freq")
                value: root.frequency
            }

            StatCard {
                Layout.fillWidth: true
                theme: root.theme
                caption: qsTr("Health")
                value: {
                    switch (root.health) {
                    case "good":     return qsTr("Good")
                    case "warning":  return qsTr("Warning")
                    case "critical": return qsTr("Critical")
                    default:         return "—"
                    }
                }
                valueColor: {
                    switch (root.health) {
                    case "good":     return root.theme.online
                    case "warning":  return root.theme.onBattery
                    case "critical": return root.theme.lowBattery
                    default:         return root.theme.textMuted
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
