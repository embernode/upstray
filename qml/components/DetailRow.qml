import QtQuick

// One label/value pair inside a Card.
//
// A row whose value the UPS does not report hides itself rather than showing a
// dash, so the card lists what this device actually knows. Layouts exclude
// invisible items, so the card shrinks to fit.
Item {
    id: root

    required property var theme
    property string label: ""
    property string value: "—"
    // Set false for a row that should stay put even with nothing to show.
    property bool hideWhenUnavailable: true

    readonly property bool available: value.length > 0 && value !== "—"

    visible: available || !hideWhenUnavailable
    implicitHeight: 44

    // Separators sit between rows, so the last *visible* row omits its own.
    // Every sibling's `visible` is read, without an early return, so this
    // re-evaluates whenever any of them appears or disappears.
    readonly property bool _hasVisibleSuccessor: {
        if (!parent)
            return false
        var siblings = parent.children
        var past = false
        var found = false
        for (var i = 0; i < siblings.length; i++) {
            if (siblings[i] === root) {
                past = true
                continue
            }
            if (past && siblings[i].visible === true)
                found = true
        }
        return found
    }

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.theme.textMuted
        font.family: root.theme.fontSans
        font.pixelSize: 13
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: root.theme.textPrimary
        font.family: root.theme.fontMono
        font.pixelSize: 13
        font.weight: Font.Bold
        elide: Text.ElideRight
        // Never let a long value collide with its label.
        width: Math.min(implicitWidth, root.width * 0.62)
        horizontalAlignment: Text.AlignRight
    }

    Rectangle {
        visible: root._hasVisibleSuccessor
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: root.theme.divider
    }
}
