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
    
    // Hide instead of close when the window X button is clicked, but if no tray
    // is available there is nowhere to hide to, so actually quit.
    onClosing: function(close_event) {
        if (trayIcon.available) {
            close_event.accepted = false
            mainWindow.hide()
        } else {
            backend.quit()
        }
    }

    color: appTheme.window

    Backend {
        id: backend
    }

    Theme {
        id: appTheme
    }

    // Single source of truth for which state we are in. The tray icon, the hero
    // colour and the alert pulse all derive from this rather than each
    // re-parsing status_text.
    readonly property string upsState: {
        if (backend.status_text === "Disconnected"
                || backend.status_text === "Connecting..."
                || backend.status_text === "Initializing...")
            return "disconnected"
        var flags = backend.status_text.split(", ")
        if (flags.indexOf("Low Battery") !== -1)
            return "lowBattery"
        if (flags.indexOf("On Battery") !== -1)
            return "onBattery"
        return "online"
    }

    function runtimeLabel(minutes) {
        if (minutes < 0)
            return "—"
        var h = Math.floor(minutes / 60)
        var m = minutes % 60
        return h + "h " + (m < 10 ? "0" : "") + m + "m"
    }

    Component.onCompleted: {
        backend.init()
        // Without a tray host the window is the only way to interact with the app.
        if (!trayIcon.available) {
            mainWindow.show()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: backend.refresh()
    }

    Platform.SystemTrayIcon {
        id: trayIcon
        visible: true
        icon.source: {
            var base = "qrc:/qt/qml/com/upstray/app/resources/icons/upstray-"
            switch (mainWindow.upsState) {
            case "disconnected": return base + "disconnected.svg"
            case "lowBattery":   return base + "lowbattery.svg"
            case "onBattery":    return base + "onbattery.svg"
            default:             return base + "online.svg"
            }
        }
        tooltip: {
            var charge = isNaN(parseInt(backend.battery_charge)) ? "—" : backend.battery_charge + "%"
            return "UPS: " + backend.status_text + "\nBattery: " + charge + "\nRuntime: " + backend.runtime_text
        }
        
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

        Hero {
            Layout.fillWidth: true
            theme: appTheme
            chargePct: backend.battery_charge_pct
            stateColor: appTheme[mainWindow.upsState]
            alert: mainWindow.upsState !== "online"
            runtimeText: mainWindow.runtimeLabel(backend.runtime_minutes)
            statusText: {
                switch (mainWindow.upsState) {
                case "disconnected": return backend.status_text.toUpperCase()
                case "lowBattery":   return qsTr("LOW BATTERY")
                case "onBattery":    return qsTr("ON BATTERY")
                default:             return qsTr("ONLINE")
                }
            }
            detailText: {
                switch (mainWindow.upsState) {
                case "disconnected": return qsTr("No connection to NUT server. Retrying…")
                case "lowBattery":   return qsTr("Battery critical. Save work — shutdown imminent.")
                case "onBattery":    return qsTr("Utility power lost. Discharging battery.")
                default:             return qsTr("Running on utility power.")
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
                theme: appTheme
                stateColor: appTheme[mainWindow.upsState]
                connected: mainWindow.upsState !== "disconnected"
                onUtility: mainWindow.upsState === "online"
                inputVoltage: backend.input_voltage
                outputVoltage: backend.output_voltage
                loadPercentage: backend.load_percentage
                powerWatts: backend.power_watts
                temperature: backend.temperature
                frequency: backend.frequency
                health: backend.health
                loadPct: backend.load_pct
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
