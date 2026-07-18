import QtQuick

// Design tokens for the v2 UI, in dark and light variants.
//
// Instantiated once in main.qml and passed down to the tabs, matching how the
// tabs already receive their other inputs. Colours are referenced through this
// object rather than inlined, so a value changes in one place.
//
// Dark is v2 as authored, with one exception: lowBattery is brightened from
// the design's #e5484d, which both reads more alert and lifts it from 4.42:1
// to 5.21:1 on the card, clearing AA.
//
// Light-variant state colours are not the dark ones re-used: v2's greens and
// ambers measure 1.9-2.4:1 against a light background, well under the 3:1
// non-text minimum. They are darkened, since these colours carry status text
// and the charge figure rather than only the ring. Most clear 4.5:1; the amber
// is deliberately held at 3.92:1, because everything darker than that stops
// reading as orange and starts reading as brown. It stays above the 3:1
// non-text floor, and no state is signalled by colour alone — the ring level,
// the label and the flow arrows all carry it too.
QtObject {
    id: theme

    // Follows the desktop colour scheme; override to force a variant.
    property bool dark: Application.styleHints.colorScheme !== Qt.Light

    // ---- surfaces ----
    readonly property color window:  dark ? "#12151a" : "#f4f5f7"
    readonly property color surface: dark ? "#171b21" : "#ffffff"
    readonly property color sunken:  dark ? "#0c0e12" : "#fafbfc"
    readonly property color border:  dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color divider: dark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.07)
    readonly property color track:   dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.08)

    // ---- text ----
    readonly property color textPrimary:   dark ? "#e7eaee" : "#12151a"
    readonly property color textTitle:     dark ? "#c4c9d0" : "#2b313a"
    readonly property color textSecondary: dark ? "#aeb4bd" : "#4a515b"
    readonly property color textMuted:     dark ? "#7f8896" : "#6b7280"

    // ---- accent ----
    readonly property color accent: dark ? "#5cc8ff" : "#0369a1"

    // ---- state ----
    readonly property color online:       dark ? "#2ecc71" : "#107a4a"
    readonly property color onBattery:    dark ? "#e8930c" : "#c26a00"
    readonly property color lowBattery:   dark ? "#f05a60" : "#c0272d"
    readonly property color disconnected: dark ? "#7a828e" : "#5a616b"

    // Tint used behind status pills, derived from the state colour it sits under.
    function soft(c) {
        return Qt.rgba(c.r, c.g, c.b, dark ? 0.16 : 0.12)
    }

    // ---- typography ----
    readonly property string fontSans: "Manrope"
    readonly property string fontMono: "JetBrains Mono"

    // ---- geometry ----
    readonly property int radiusCard:  12
    readonly property int radiusInput:  9
    readonly property int radiusPill:  20
}
