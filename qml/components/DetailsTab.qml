import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Everything the UPS reports about itself, grouped into identity and power.
//
// Rows the device does not report hide themselves, and a group whose rows are
// all missing hides along with its heading — so this lists what the hardware
// actually knows rather than a column of dashes. Not every UPS reports every
// variable; efficiency in particular is absent on many.
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
    property string efficiency: ""
    property string powerWatts: "—"
    property string temperature: "—"
    property string loadPercentage: ""
    property string batteryCharge: ""

    readonly property string _firmwareText: firmware === "—" || firmware.length === 0
                                            ? firmware : "v" + firmware
    readonly property string _loadText: powerWatts === "—" ? loadPercentage
                                                           : loadPercentage + " · " + powerWatts
    readonly property string _chargeText: isNaN(parseInt(batteryCharge)) ? "—"
                                                                        : batteryCharge + "%"

    // True when any supplied value carries something to show. Reads every
    // entry rather than returning early, so it re-evaluates whenever any of
    // them changes.
    function _any(values) {
        var found = false
        for (var i = 0; i < values.length; i++) {
            if (values[i] !== undefined && values[i].length > 0 && values[i] !== "—")
                found = true
        }
        return found
    }

    readonly property bool _hasDevice: _any([model, serialNumber, _firmwareText, connection])
    readonly property bool _hasPower: _any([inputVoltage, outputVoltage, frequency, efficiency,
                                            _loadText, temperature, _chargeText])

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
                visible: root._hasDevice
                theme: root.theme
                text: qsTr("Device")
            }

            Card {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18 + scroller.gutter
                Layout.preferredHeight: deviceRows.implicitHeight + 8
                visible: root._hasDevice
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
                        value: root._firmwareText
                    }
                    DetailRow {
                        Layout.fillWidth: true
                        theme: root.theme
                        label: qsTr("Connection")
                        value: root.connection
                    }
                }
            }

            SectionHeading {
                Layout.leftMargin: 18
                Layout.topMargin: 20
                Layout.bottomMargin: 10
                visible: root._hasPower
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
                visible: root._hasPower
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
                        label: qsTr("Efficiency")
                        value: root.efficiency
                    }
                    DetailRow {
                        Layout.fillWidth: true
                        theme: root.theme
                        label: qsTr("Load")
                        value: root._loadText
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
                        value: root._chargeText
                    }
                }
            }
        }
    }
}
