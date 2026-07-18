import QtQuick
import QtQuick.Layouts

// Live power view: where power is flowing, how hard the UPS is working, and
// the three figures worth watching while it does.
Item {
    id: root

    property var theme
    property color stateColor: theme ? theme.online : "#2ecc71"
    // False while on battery — dims the utility-side arrow and reddens the input.
    property bool onUtility: true
    property bool connected: true

    property string inputVoltage: "—"
    property string outputVoltage: "—"
    property string loadPercentage: "—"
    property string powerWatts: "—"
    property string temperature: "—"
    property string frequency: "—"
    property string health: ""
    property real loadPct: -1

    readonly property color _idle: theme ? Qt.rgba(theme.textMuted.r, theme.textMuted.g,
                                                   theme.textMuted.b, 0.45)
                                        : "#3a4049"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 16

        // ---- power flow strip ----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 74
            radius: root.theme ? root.theme.radiusCard : 12
            color: root.theme ? root.theme.surface : "transparent"
            border.width: 1
            border.color: root.theme ? root.theme.border : "transparent"

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
                    valueColor: !root.connected ? (root.theme ? root.theme.textMuted : "#7f8896")
                              : root.onUtility  ? root.stateColor
                                                : (root.theme ? root.theme.lowBattery : "#e5484d")
                }

                FlowArrow {
                    Layout.alignment: Qt.AlignVCenter
                    arrowColor: root.connected && root.onUtility ? root.stateColor : root._idle
                }

                FlowCell {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    theme: root.theme
                    caption: qsTr("Load")
                    value: root.loadPercentage
                    showDividers: true
                    valueColor: root.connected ? root.stateColor
                                               : (root.theme ? root.theme.textMuted : "#7f8896")
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
            radius: root.theme ? root.theme.radiusCard : 12
            color: root.theme ? root.theme.surface : "transparent"
            border.width: 1
            border.color: root.theme ? root.theme.border : "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Load")
                        color: root.theme ? root.theme.textSecondary : "#aeb4bd"
                        font.family: root.theme ? root.theme.fontSans : "sans-serif"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.powerWatts === "—" ? root.loadPercentage
                                                      : root.loadPercentage + " · " + root.powerWatts
                        color: root.theme ? root.theme.textPrimary : "#e7eaee"
                        font.family: root.theme ? root.theme.fontMono : "monospace"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: 5
                    color: root.theme ? root.theme.track : "#22ffffff"

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        width: root.loadPct >= 0 ? parent.width * Math.min(100, root.loadPct) / 100 : 0
                        visible: width > 0

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.theme ? root.theme.online : "#2ecc71" }
                            GradientStop { position: 1.0; color: root.theme ? root.theme.accent : "#5cc8ff" }
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
                    if (!root.theme)
                        return "#e7eaee"
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
