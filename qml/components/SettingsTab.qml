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

        ColumnLayout {
            width: parent.width
            anchors.margins: 15
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
