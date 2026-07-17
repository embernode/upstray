import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    // Reference to the global backend (set by parent via property alias in main.qml loader)
    property QtObject backend: null

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        padding: 15

        ColumnLayout {
            width: parent.width
            spacing: 20

            // General Settings
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Label { text: "General"; font.bold: true }

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: "Auto-start with system"; font.pixelSize: 14 }
                        Label { text: "Launch monitor on login"; color: palette.placeholderText; font.pixelSize: 12 }
                    }
                    Switch {
                        id: autostartSwitch
                        checked: root.backend ? root.backend.autostart_enabled : false
                        onToggled: if (root.backend) root.backend.set_autostart(checked)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: "Notifications"; font.pixelSize: 14 }
                        Label { text: "Show system notifications on power events"; color: palette.placeholderText; font.pixelSize: 12 }
                    }
                    Switch {
                        id: notificationsSwitch
                        checked: root.backend ? root.backend.notifications_enabled : true
                        onToggled: if (root.backend) root.backend.set_notifications(checked)
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: palette.mid }

            // Network Settings
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Label { text: "Network Connection"; font.bold: true }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label { text: "IP Address / Hostname"; font.pixelSize: 12 }
                    TextField {
                        id: hostField
                        Layout.fillWidth: true
                        text: root.backend ? root.backend.nut_host : "localhost"
                        placeholderText: "localhost"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label { text: "Port"; font.pixelSize: 12 }
                    TextField {
                        id: portField
                        Layout.fillWidth: true
                        text: root.backend ? root.backend.nut_port : "3493"
                        placeholderText: "3493"
                        inputMethodHints: Qt.ImhDigitsOnly
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: palette.mid }

            // UPS Device
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Label { text: "UPS Device"; font.bold: true }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label { text: "Device to monitor"; font.pixelSize: 12 }
                    ComboBox {
                        id: upsCombo
                        Layout.fillWidth: true
                        model: {
                            var list = ["Auto (first device)"]
                            if (root.backend && root.backend.available_ups.length > 0)
                                list = list.concat(root.backend.available_ups.split(","))
                            // Keep the configured device visible even when the live list
                            // is empty (disconnected / before first poll), so saving does
                            // not silently fall back to Auto.
                            if (root.backend && root.backend.ups_name.length > 0 && list.indexOf(root.backend.ups_name) === -1)
                                list.push(root.backend.ups_name)
                            return list
                        }

                        function syncFromBackend() {
                            if (!root.backend || root.backend.ups_name.length === 0) {
                                currentIndex = 0
                                return
                            }
                            var idx = model.indexOf(root.backend.ups_name)
                            currentIndex = idx === -1 ? 0 : idx
                        }

                        Component.onCompleted: syncFromBackend()
                        onModelChanged: if (!popup.visible) syncFromBackend()

                        Connections {
                            target: root.backend
                            function onUps_nameChanged() {
                                if (!upsCombo.popup.visible) upsCombo.syncFromBackend()
                            }
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    text: "Save Device"
                    onClicked: {
                        if (root.backend) {
                            root.backend.save_ups_name(upsCombo.currentIndex === 0 ? "" : upsCombo.currentText)
                            upsCombo.syncFromBackend()
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: palette.mid }

            // Actions
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    Layout.fillWidth: true
                    text: "Save Network Settings"
                    onClicked: {
                        if (root.backend) {
                            root.backend.save_network_settings(hostField.text, portField.text)
                            hostField.text = root.backend.nut_host
                            portField.text = root.backend.nut_port
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "ℹ The connection will reconnect automatically after saving."
                    color: palette.placeholderText
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
