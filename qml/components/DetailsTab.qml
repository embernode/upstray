import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Everything the UPS reports about itself, grouped into identity and power.
Item {
    id: root

    required property var theme

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

    // Flickable rather than ScrollView: ScrollView creates its own scroll bars,
    // and assigning one to it puts the assigned bar at the origin — it rendered
    // down the left of the content instead of the right edge.
    Flickable {
        id: scroller
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            policy: ScrollBar.AsNeeded
        }

        // A bare Flickable moves only a few pixels per wheel notch; ScrollView
        // supplied this handling, so replacing it lost the wheel speed too.
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            onWheel: function (event) {
                const limit = Math.max(0, scroller.contentHeight - scroller.height)
                const delta = (event.angleDelta.y / 120) * 90
                scroller.contentY = Math.max(0, Math.min(limit, scroller.contentY - delta))
            }
        }

        // The bar overlays the content rather than displacing it, so without
        // this it eats the right-hand padding rather than sitting beside it.
        readonly property real gutter: scrollBar.visible ? scrollBar.width : 0

        ColumnLayout {
            id: content
            width: scroller.width
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
                Layout.rightMargin: 18 + scroller.gutter
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
                        value: root.firmware === "—" ? root.firmware : "v" + root.firmware
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
                color: root.theme.headingPower
                text: qsTr("Power metrics")
            }

            Card {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18 + scroller.gutter
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
