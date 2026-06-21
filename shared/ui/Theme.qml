pragma Singleton
import QtQuick
import org.kde.kirigami as Kirigami

/*
 * Lattice design tokens.
 *
 * Colours are intentionally NOT baked in here: components read
 * Kirigami.Theme directly so they track the active Plasma colour
 * scheme (and therefore light/dark wallpapers) automatically.
 *
 * This singleton holds the things that are constant across the suite:
 * type, metrics, motion, and a couple of colour helpers.
 */
QtObject {
    id: theme

    // ---- Type -------------------------------------------------------------
    // Data / numerals: a mono Nerd Font so glyph icons render inline.
    readonly property string mono: "CaskaydiaCove Nerd Font Mono"
    // Quiet sans for instrument captions.
    readonly property string sans: "Inter"

    readonly property int fsMicro: Math.round(Kirigami.Theme.smallFont.pixelSize * 0.78)
    readonly property int fsCaption: Math.round(Kirigami.Theme.smallFont.pixelSize * 0.92)
    readonly property int fsBody: Kirigami.Theme.defaultFont.pixelSize
    readonly property int fsReadout: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.55)
    readonly property int fsHero: Math.round(Kirigami.Theme.defaultFont.pixelSize * 2.6)

    // Caption tracking (letter-spacing) for the small-caps instrument labels.
    readonly property real caps: 2.2

    // ---- Metrics ----------------------------------------------------------
    readonly property int unit: Kirigami.Units.gridUnit
    readonly property int xs: Math.round(unit * 0.25)
    readonly property int sm: Math.round(unit * 0.45)
    readonly property int md: Math.round(unit * 0.75)
    readonly property int lg: unit
    readonly property int xl: Math.round(unit * 1.6)

    // True hairline that survives HiDPI without disappearing.
    readonly property real hair: Math.max(1, Math.round(Screen.devicePixelRatio))

    // ---- Motion -----------------------------------------------------------
    readonly property int tFast: 140
    readonly property int tMed: 280
    readonly property int tSlow: 600
    readonly property int easing: Easing.OutCubic

    // ---- Colour helpers ---------------------------------------------------
    // Default accent follows the user's highlight colour -> matches desktop.
    readonly property color accentDefault: Kirigami.Theme.highlightColor

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // Foreground stops, derived from the scheme text colour.
    function fg(a)   { return alpha(Kirigami.Theme.textColor, a === undefined ? 1.0 : a) }
    readonly property color ink:    fg(0.92)
    readonly property color dim:    fg(0.55)
    readonly property color faint:  fg(0.30)
    readonly property color ghost:  fg(0.14)   // hairlines / ticks
    readonly property color wash:   fg(0.06)   // fills

    // Status hues that still defer to the scheme's contrast.
    readonly property color warn: Qt.rgba(0.93, 0.62, 0.20, 1.0)
    readonly property color hot:  Qt.rgba(0.90, 0.34, 0.34, 1.0)
    readonly property color cool: Kirigami.Theme.highlightColor
}
