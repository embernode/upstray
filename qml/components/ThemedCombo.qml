import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

// Dropdown styled to match the text inputs, including its popup — the stock
// popup keeps the ambient desktop style and looks pasted on otherwise.
ComboBox {
    id: root

    property var theme

    readonly property color _text: theme ? theme.textPrimary : "#e7eaee"
    readonly property color _surface: theme ? theme.surface : "#171b21"

    implicitHeight: 42
    leftPadding: 12
    rightPadding: 34

    background: Rectangle {
        radius: root.theme ? root.theme.radiusInput : 9
        color: root.theme ? root.theme.sunken : "#0c0e12"
        border.width: 1
        border.color: root.activeFocus || root.popup.visible
            ? (root.theme ? root.theme.accent : "#5cc8ff")
            : (root.theme ? root.theme.inputBorder : "#2a3038")

        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    contentItem: Text {
        text: root.displayText
        color: root._text
        font.family: root.theme ? root.theme.fontSans : "sans-serif"
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
            strokeColor: root.theme ? root.theme.textMuted : "#7f8896"
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
            font.family: root.theme ? root.theme.fontSans : "sans-serif"
            font.pixelSize: 13
            font.weight: root.currentIndex === index ? Font.Bold : Font.Medium
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            color: highlighted
                ? (root.theme ? Qt.rgba(root.theme.accent.r, root.theme.accent.g,
                                        root.theme.accent.b, 0.14) : "#204050")
                : "transparent"
        }
    }

    popup: Popup {
        y: root.height + 4
        width: root.width
        implicitHeight: Math.min(contentItem.implicitHeight + 8, 220)
        padding: 4

        background: Rectangle {
            radius: root.theme ? root.theme.radiusInput : 9
            color: root._surface
            border.width: 1
            border.color: root.theme ? root.theme.inputBorder : "#2a3038"
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
