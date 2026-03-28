import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1 as Platform
import QtQml 2.15

import com.upstray.app 1.0
import "components"

ApplicationWindow {
    id: mainWindow
    width: 460
    height: 550
    visible: false
    title: qsTr("UpsTray")
    
    // Hide instead of close when the window X button is clicked
    onClosing: function(close_event) {
        close_event.accepted = false
        mainWindow.hide()
    }

    Backend {
        id: backend
    }

    Component.onCompleted: {
        backend.init()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: backend.refresh()
    }

    Platform.SystemTrayIcon {
        visible: true
        icon.name: backend.icon_name
        tooltip: "UPS: " + backend.status_text + " (" + backend.battery_charge + "%)"
        
        onActivated: function(reason) {
            if (reason === Platform.SystemTrayIcon.Trigger) {
                if (mainWindow.visible) {
                    mainWindow.hide()
                } else {
                    mainWindow.show()
                    mainWindow.raise()
                    mainWindow.requestActivate()
                }
            }
        }

        menu: Platform.Menu {
            Platform.MenuItem {
                text: qsTr("Show Details")
                onTriggered: {
                    mainWindow.show()
                    mainWindow.raise()
                    mainWindow.requestActivate()
                }
            }
            Platform.MenuItem {
                text: qsTr("Settings...")
                onTriggered: {
                    mainWindow.show()
                    mainWindow.raise()
                    mainWindow.requestActivate()
                    customTabBarContainer.currentIndex = 2
                }
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: qsTr("Quit")
                onTriggered: backend.quit()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Label {
                text: "⏻ UPS Monitor"
                font.bold: true
                font.pixelSize: 18
            }

            Item { Layout.fillWidth: true } // spacer to push badges to right

            // Connection Badge
            Rectangle {
                color: "transparent"
                border.color: palette.mid
                radius: 12
                implicitWidth: connectionLabel.implicitWidth + 16
                implicitHeight: connectionLabel.implicitHeight + 8
                Label {
                    id: connectionLabel
                    anchors.centerIn: parent
                    text: backend.connection_type === "USB" ? "🔌 USB" : "🌐 " + backend.connection_type
                    font.pixelSize: 12
                }
            }
            // Status Badge
            Rectangle {
                property bool isOnline: backend.status_text === "OL" || backend.status_text === "Online"
                color: isOnline ? "#052e16" : (backend.status_text === "Disconnected" ? palette.midlight : "#450a0a") // Very dark shade
                radius: 6 // Squircle shape instead of pill
                implicitWidth: statusLabel.implicitWidth + 24 // Added padding at ends
                implicitHeight: statusLabel.implicitHeight + 8
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Rectangle { 
                        width: 8; height: 8; radius: 4
                        color: parent.parent.isOnline ? "#22c55e" : (backend.status_text === "Disconnected" ? palette.text : "#ef4444") 
                    }
                    Label {
                        id: statusLabel
                        text: parent.parent.isOnline ? "Online" : (backend.status_text === "Disconnected" ? "Disconnected" : backend.status_text)
                        color: "white"
                        font.bold: true
                        font.pixelSize: 12
                    }
                }
            }
        }

        // Custom Tab segmented control
        Rectangle {
            id: customTabBarContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            color: palette.alternateBase
            radius: 8

            property int currentIndex: 0

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                Repeater {
                    model: ["📈 Monitor", "📊 Details", "⚡ Settings"]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: customTabBarContainer.currentIndex === index ? palette.base : "transparent"
                        radius: 6

                        Label {
                            anchors.centerIn: parent
                            text: modelData
                            color: customTabBarContainer.currentIndex === index ? palette.text : palette.placeholderText
                            font.bold: customTabBarContainer.currentIndex === index
                            font.pixelSize: 13
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: customTabBarContainer.currentIndex = index
                        }
                    }
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: customTabBarContainer.currentIndex

            MonitorTab {
                upsName: backend.manufacturer_model
                statusText: backend.status_text
                batteryCharge: backend.battery_charge
                runtimeText: backend.runtime_text
                inputVoltage: backend.input_voltage
                outputVoltage: backend.output_voltage
                loadPercentage: backend.load_percentage
                temperature: backend.temperature
                healthStatus: backend.health
                connectionType: backend.connection_type
            }

            DetailsTab {
                model: backend.manufacturer_model
                serialNumber: backend.serial_number
                firmware: backend.firmware_version
                connection: backend.connection_type
                inputVoltage: backend.input_voltage
                outputVoltage: backend.output_voltage
                frequency: backend.frequency
                efficiency: backend.efficiency
                loadPercentage: backend.load_percentage
                batteryCharge: backend.battery_charge
            }

            SettingsTab {
                backend: backend
            }
        }
    }
}
