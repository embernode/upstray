import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Configuration: startup and notification behaviour, where the NUT server is,
// and which of its devices to watch.
Item {
    id: root

    required property var theme
    property QtObject backend: null

    readonly property string saveIcon: "M5 3h11l3 3v15H5z M8 3v5h6V3 M8 21v-6h8v6"

    Flickable {
        id: scroller
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // Travel per wheel notch.
        readonly property real wheelStep: 130

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            policy: ScrollBar.AsNeeded
        }


        readonly property real gutter: scrollBar.visible ? scrollBar.width : 0

        ColumnLayout {
            id: content
            width: scroller.width
            spacing: 0

            // ---- general ----
            SectionHeading {
                Layout.leftMargin: 18
                Layout.topMargin: 18
                Layout.bottomMargin: 12
                theme: root.theme
                text: qsTr("General")
            }

            Card {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18 + scroller.gutter
                Layout.preferredHeight: generalRows.implicitHeight + 8
                theme: root.theme

                ColumnLayout {
                    id: generalRows
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        spacing: 12

                        ColumnLayout {
                            spacing: 2

                            Text {
                                text: qsTr("Auto-start with system")
                                color: root.theme.textPrimary
                                font.family: root.theme.fontSans
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: qsTr("Launch monitor on login")
                                color: root.theme.textMuted
                                font.family: root.theme.fontSans
                                font.pixelSize: 12
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ToggleSwitch {
                            Layout.alignment: Qt.AlignVCenter
                            theme: root.theme
                            checked: root.backend ? root.backend.autostart_enabled : false
                            onToggleRequested: {
                                if (root.backend)
                                    root.backend.set_autostart(!root.backend.autostart_enabled)
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: root.theme.divider
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        spacing: 12

                        ColumnLayout {
                            spacing: 2

                            Text {
                                text: qsTr("Notifications")
                                color: root.theme.textPrimary
                                font.family: root.theme.fontSans
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: qsTr("Alert on power events")
                                color: root.theme.textMuted
                                font.family: root.theme.fontSans
                                font.pixelSize: 12
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ToggleSwitch {
                            Layout.alignment: Qt.AlignVCenter
                            theme: root.theme
                            checked: root.backend ? root.backend.notifications_enabled : true
                            onToggleRequested: {
                                if (root.backend)
                                    root.backend.set_notifications(!root.backend.notifications_enabled)
                            }
                        }
                    }
                }
            }

            // ---- nut server ----
            SectionHeading {
                Layout.leftMargin: 18
                Layout.topMargin: 22
                Layout.bottomMargin: 12
                theme: root.theme
                text: qsTr("NUT Server")
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18 + scroller.gutter
                spacing: 10

                ThemedField {
                    id: hostField
                    Layout.fillWidth: true
                    Layout.preferredWidth: 2
                    theme: root.theme
                    label: qsTr("Host")
                    placeholder: "localhost"
                    text: root.backend ? root.backend.nut_host : "localhost"
                }

                ThemedField {
                    id: portField
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    theme: root.theme
                    label: qsTr("Port")
                    placeholder: "3493"
                    inputHints: Qt.ImhDigitsOnly
                    text: root.backend ? root.backend.nut_port : "3493"
                }
            }

            ThemedButton {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: 12
                Layout.rightMargin: 18 + scroller.gutter
                theme: root.theme
                text: qsTr("Save Network Settings")
                iconPath: root.saveIcon
                onClicked: {
                    if (!root.backend)
                        return
                    root.backend.save_network_settings(hostField.text, portField.text)
                    // The backend normalises and may reject; show what it stored.
                    hostField.text = root.backend.nut_host
                    portField.text = root.backend.nut_port
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18 + scroller.gutter
                Layout.topMargin: 8
                text: qsTr("The connection reconnects automatically after saving.")
                color: root.theme.textMuted
                font.family: root.theme.fontSans
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            // ---- device ----
            SectionHeading {
                Layout.leftMargin: 18
                Layout.topMargin: 22
                Layout.bottomMargin: 12
                theme: root.theme
                text: qsTr("UPS Device")
            }

            Text {
                Layout.leftMargin: 18
                Layout.bottomMargin: 6
                text: qsTr("Device to monitor")
                color: root.theme.textMuted
                font.family: root.theme.fontSans
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            ThemedCombo {
                id: upsCombo
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18 + scroller.gutter
                theme: root.theme

                model: {
                    var list = [qsTr("Auto (first device)")]
                    if (root.backend && root.backend.available_ups.length > 0)
                        list = list.concat(root.backend.available_ups.split(","))
                    // Keep the configured device visible even when the live list
                    // is empty (disconnected / before first poll), so saving does
                    // not silently fall back to Auto.
                    if (root.backend && root.backend.ups_name.length > 0
                            && list.indexOf(root.backend.ups_name) === -1)
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
                        if (!upsCombo.popup.visible)
                            upsCombo.syncFromBackend()
                    }
                }
            }

            ThemedButton {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: 12
                Layout.rightMargin: 18 + scroller.gutter
                Layout.bottomMargin: 22
                theme: root.theme
                text: qsTr("Save Device")
                iconPath: root.saveIcon
                onClicked: {
                    if (!root.backend)
                        return
                    root.backend.save_ups_name(upsCombo.currentIndex === 0 ? "" : upsCombo.currentText)
                    upsCombo.syncFromBackend()
                }
            }
        }
    }

    // Wheel scrolling goes through MouseArea, not WheelHandler: verified with a
    // probe racing the two, WheelHandler receives no wheel events at all on this
    // setup while MouseArea does. Without this, scrolling falls back to
    // Flickable's built-in handling, which is only a few pixels per detent.
    //
    // acceptedButtons is NoButton so this takes the wheel only and lets clicks
    // through to whatever is underneath.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function (wheel) {
            const limit = Math.max(0, scroller.contentHeight - scroller.height)
            // angleDelta is eighths of a degree, 120 to a detent. A
            // high-resolution wheel sends fractions of that which sum to 120 per
            // detent, so scaling proportionally gives one step per detent either
            // way. pixelDelta is the fallback for devices that send only that.
            const delta = wheel.angleDelta.y !== 0
                        ? (wheel.angleDelta.y / 120) * scroller.wheelStep
                        : wheel.pixelDelta.y
            scroller.contentY = Math.max(0, Math.min(limit, scroller.contentY - delta))
        }
    }

}
