import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Everything the UPS reports about itself, grouped into identity and power.
Item {
    id: root

    property var theme

    property string model: ""
    property string serialNumber: ""
    property string firmware: ""
    property string connection: ""

    property string inputVoltage: ""
    property string outputVoltage: ""
    property string frequency: ""
    property string powerWatts: "—"
    property string temperature: "—"
    property string loadPercentage: ""
    property string batteryCharge: ""

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: root.width
            spacing: 0

            SectionHeading {
                Layout.leftMargin: 18
                Layout.topMargin: 18
                Layout.bottomMargin: 10
                theme: root.theme
                text: qsTr("Device")
            }

            Card {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.preferredHeight: deviceRows.implicitHeight + 8
                theme: root.theme

                ColumnLayout {
                    id: deviceRows
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 0

                    DetailRow {
                        Layout.fillWidth: true
                        theme: root.theme
                        label: qsTr("Model")
                        value: root.model
                    }
                    DetailRow {
                        Layout.fillWidth: true
                        theme: root.theme
                        label: qsTr("Serial")
                        value: root.serialNumber
                    }
                    DetailRow {
                        Layout.fillWidth: true
                        theme: root.theme
                        label: qsTr("Firmware")
                        value: root.firmware
                    }
                    DetailRow {
                        Layout.fillWidth: true
                        theme: root.theme
                        label: qsTr("Connection")
                        value: root.connection
                        last: true
                    }
                }
            }

            SectionHeading {
                Layout.leftMargin: 18
                Layout.topMargin: 20
                Layout.bottomMargin: 10
                theme: root.theme
                color: root.theme ? root.theme.headingPower : "#f0a020"
                text: qsTr("Power metrics")
            }

            Card {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.bottomMargin: 24
                Layout.preferredHeight: powerRows.implicitHeight + 8
                theme: root.theme

                ColumnLayout {
                    id: powerRows
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 0

                    DetailRow {
                        Layout.fillWidth: true
                        theme: root.theme
                        label: qsTr("Input Voltage")
                        value: root.inputVoltage
                    }
                    DetailRow {
                        Layout.fillWidth: true
                        theme: root.theme
                        label: qsTr("Output Voltage")
                        value: root.outputVoltage
                    }
                    DetailRow {
                        Layout.fillWidth: true
                        theme: root.theme
                        label: qsTr("Frequency")
                        value: root.frequency
                    }
                    DetailRow {
                        Layout.fillWidth: true
                        theme: root.theme
                        label: qsTr("Load")
                        value: root.powerWatts === "—" ? root.loadPercentage
                                                       : root.loadPercentage + " · " + root.powerWatts
                    }
                    DetailRow {
                        Layout.fillWidth: true
                        theme: root.theme
                        label: qsTr("Temperature")
                        value: root.temperature
                    }
                    DetailRow {
                        Layout.fillWidth: true
                        theme: root.theme
                        label: qsTr("Battery Charge")
                        value: isNaN(parseInt(root.batteryCharge)) ? "—" : root.batteryCharge + "%"
                        last: true
                    }
                }
            }
        }
    }
}
