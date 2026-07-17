import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property string model: ""
    property string serialNumber: ""
    property string firmware: ""
    property string connection: ""
    
    property string inputVoltage: ""
    property string outputVoltage: ""
    property string frequency: ""
    property string efficiency: ""
    property string loadPercentage: ""
    property string batteryCharge: ""

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        padding: 15

        ColumnLayout {
            width: parent.width
            spacing: 20

            // Device Information
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Label {
                    text: "⏻ Device Information"
                    font.bold: true
                    font.pixelSize: 14
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Model"; color: palette.placeholderText }
                    Item { Layout.fillWidth: true }
                    Label { text: root.model; font.bold: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Serial Number"; color: palette.placeholderText }
                    Item { Layout.fillWidth: true }
                    Label { text: root.serialNumber; font.bold: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Firmware"; color: palette.placeholderText }
                    Item { Layout.fillWidth: true }
                    Label { text: root.firmware === "—" ? "—" : "v" + root.firmware; font.bold: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Connection"; color: palette.placeholderText }
                    Item { Layout.fillWidth: true }
                    Label { text: root.connection; font.bold: true }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: palette.mid }

            // Power Metrics
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Label {
                    text: "⚡ Power Metrics"
                    font.bold: true
                    font.pixelSize: 14
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Input Voltage"; color: palette.placeholderText }
                    Item { Layout.fillWidth: true }
                    Label { text: root.inputVoltage; font.bold: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Output Voltage"; color: palette.placeholderText }
                    Item { Layout.fillWidth: true }
                    Label { text: root.outputVoltage; font.bold: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Frequency"; color: palette.placeholderText }
                    Item { Layout.fillWidth: true }
                    Label { text: root.frequency; font.bold: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Efficiency"; color: palette.placeholderText }
                    Item { Layout.fillWidth: true }
                    Label { text: root.efficiency; font.bold: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Load"; color: palette.placeholderText }
                    Item { Layout.fillWidth: true }
                    Label { text: root.loadPercentage; font.bold: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Battery Charge"; color: palette.placeholderText }
                    Item { Layout.fillWidth: true }
                    Label { text: !isNaN(parseInt(root.batteryCharge)) ? root.batteryCharge + "%" : "—"; font.bold: true }
                }
            }


        }
    }
}
