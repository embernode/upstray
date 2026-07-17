import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property string upsName: ""
    property string statusText: ""
    property string batteryCharge: ""
    property string runtimeText: ""
    property string inputVoltage: ""
    property string outputVoltage: ""
    property string loadPercentage: ""
    property string temperature: ""
    property string healthStatus: ""
    property string connectionType: "USB"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        // Battery Status
        ColumnLayout {
            id: batterySection
            Layout.fillWidth: true
            spacing: 6

            property bool chargeKnown: !isNaN(parseInt(root.batteryCharge))

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: "\uD83D\uDD0B"
                    font.pixelSize: 14
                    color: !batterySection.chargeKnown ? palette.placeholderText : (parseInt(root.batteryCharge) > 60 ? "#22c55e" : (parseInt(root.batteryCharge) > 30 ? "#eab308" : "#ef4444"))
                }
                Label {
                    text: "Battery"
                    font.pixelSize: 14
                    color: palette.text
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: batterySection.chargeKnown ? root.batteryCharge + "%" : "\u2014"
                    font.bold: true
                    font.pixelSize: 14
                    color: !batterySection.chargeKnown ? palette.placeholderText : (parseInt(root.batteryCharge) > 60 ? "#22c55e" : (parseInt(root.batteryCharge) > 30 ? "#eab308" : "#ef4444"))
                }
            }
            // Custom progress bar (bypasses Breeze style override)
            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: palette.placeholderText
                opacity: 0.3

                Rectangle {
                    width: {
                        if (!batterySection.chargeKnown) return parent.width;
                        var pct = parseInt(root.batteryCharge);
                        return (pct / 100.0) * parent.width;
                    }
                    height: parent.height
                    radius: 3
                    color: !batterySection.chargeKnown ? palette.placeholderText : (parseInt(root.batteryCharge) > 60 ? "#22c55e" : (parseInt(root.batteryCharge) > 30 ? "#eab308" : "#ef4444"))
                    opacity: 1.0
                }
            }
        }

        // Load Status
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: "\u223F" // Squiggly for load
                    color: "#3b82f6"
                    font.pixelSize: 16
                }
                Label {
                    text: "Load"
                    font.pixelSize: 14
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: root.loadPercentage
                    font.bold: true
                    font.pixelSize: 14
                }
            }
            // Custom progress bar (bypasses Breeze style override)
            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: palette.placeholderText
                opacity: 0.3

                Rectangle {
                    width: {
                        var pct = parseFloat(root.loadPercentage);
                        return isNaN(pct) ? 0 : (pct / 100.0) * parent.width;
                    }
                    height: parent.height
                    radius: 3
                    color: palette.text
                    opacity: 1.0
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: palette.mid
        }

        // Grid Info
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            // Column 1 Wrapper
            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: 100
                Layout.preferredHeight: col1Layout.implicitHeight
                
                ColumnLayout {
                    id: col1Layout
                    anchors.fill: parent
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        RowLayout {
                            spacing: 4
                            Label { text: "⏱"; color: palette.placeholderText; font.pixelSize: 12 }
                            Label { text: "Runtime"; color: palette.placeholderText; font.pixelSize: 12 }
                        }
                        Label { text: root.runtimeText.replace(" min", "m"); font.bold: true; font.pixelSize: 14 }
                    }

                    ColumnLayout {
                        spacing: 2
                        RowLayout {
                            spacing: 4
                            Label { text: "↘"; color: palette.placeholderText; font.pixelSize: 12 }
                            Label { text: "Input"; color: palette.placeholderText; font.pixelSize: 12 }
                        }
                        Label { text: root.inputVoltage; font.bold: true; font.pixelSize: 14 }
                    }
                }
            }

            // Column 2 Wrapper
            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: 100
                Layout.preferredHeight: col2Layout.implicitHeight

                ColumnLayout {
                    id: col2Layout
                    anchors.fill: parent
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        RowLayout {
                            spacing: 4
                            Label { text: "🌡"; color: palette.placeholderText; font.pixelSize: 12 }
                            Label { text: "Temperature"; color: palette.placeholderText; font.pixelSize: 12 }
                        }
                        Label { text: root.temperature; font.bold: true; font.pixelSize: 14 }
                    }

                    ColumnLayout {
                        spacing: 2
                        RowLayout {
                            spacing: 4
                            Label { text: "↗"; color: palette.placeholderText; font.pixelSize: 12 }
                            Label { text: "Output"; color: palette.placeholderText; font.pixelSize: 12 }
                        }
                        Label { text: root.outputVoltage; font.bold: true; font.pixelSize: 14 }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: palette.mid
        }

        // Footer System Health
        RowLayout {
            Layout.fillWidth: true
            RowLayout {
                spacing: 4
                Label { text: "⚡"; color: palette.placeholderText; font.pixelSize: 14 }
                Label {
                    text: "System Health"
                    color: palette.placeholderText
                    font.pixelSize: 13
                }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                color: root.healthStatus === "good" ? palette.text : (root.healthStatus === "warning" ? "#FFC107" : "#ef4444")
                radius: 6
                implicitWidth: healthLabel.implicitWidth + 24
                implicitHeight: healthLabel.implicitHeight + 10
                Label {
                    id: healthLabel
                    anchors.centerIn: parent
                    text: root.healthStatus.charAt(0).toUpperCase() + root.healthStatus.slice(1)
                    color: root.healthStatus === "good" ? palette.base : "white"
                    font.bold: true
                    font.pixelSize: 12
                }
            }
        }
        
        Item { Layout.fillHeight: true }
    }
}
