import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

// Dropdown styled to match the text inputs, including its popup — the stock
// popup keeps the ambient desktop style and looks pasted on otherwise.
ComboBox {
    id: root

    required property var theme

    readonly property color _text: theme.textPrimary
    readonly property color _surface: theme.surface

    implicitHeight: 42
    leftPadding: 12
    rightPadding: 34

    background: Rectangle {
        radius: root.theme.radiusInput
        color: root.theme.sunken
        border.width: 1
        border.color: root.activeFocus || root.popup.visible
            ? root.theme.accent
            : root.theme.inputBorder

        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    contentItem: Text {
        text: root.displayText
        color: root._text
        font.family: root.theme.fontSans
        font.pixelSize: 13
        font.weight: Font.Medium
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Shape {
        x: root.width - 26
        y: (root.height - 14) / 2
        width: 14
        height: 14
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.theme.textMuted
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 3; startY: 5
            PathLine { x: 7; y: 9 }
            PathLine { x: 11; y: 5 }
        }
    }

    delegate: ItemDelegate {
        required property var modelData
        required property int index

        width: root.width
        height: 36
        highlighted: root.highlightedIndex === index

        contentItem: Text {
            text: modelData
            color: root._text
            font.family: root.theme.fontSans
            font.pixelSize: 13
            font.weight: root.currentIndex === index ? Font.Bold : Font.Medium
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            color: highlighted
                ? Qt.rgba(root.theme.accent.r, root.theme.accent.g,
                          root.theme.accent.b, 0.14)
                : "transparent"
        }
    }

    popup: Popup {
        y: root.height + 4
        width: root.width
        implicitHeight: Math.min(contentItem.implicitHeight + 8, 220)
        padding: 4

        background: Rectangle {
            radius: root.theme.radiusInput
            color: root._surface
            border.width: 1
            border.color: root.theme.inputBorder
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }
}
