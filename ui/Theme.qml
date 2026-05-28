pragma Singleton
import QtQuick

QtObject {
    id: theme

    // --- Mode Control ---
    // 0 = follow system, 1 = force dark, 2 = force light
    property int themeMode: 0

    // Resolved: is the current theme dark?
    readonly property bool isDark: {
        if (themeMode === 1) return true
        if (themeMode === 2) return false
        // Follow system (Qt 6.5+)
        return Qt.styleHints.colorScheme === Qt.Dark
    }

    function toggleTheme() {
        if (themeMode === 0) {
            // System → force opposite of current
            themeMode = isDark ? 2 : 1
        } else if (themeMode === 1) {
            themeMode = 2
        } else {
            themeMode = 1
        }
    }

    // --- Core Palette ---
    readonly property color background:      isDark ? "#0B0F19" : "#F5F7FA"
    readonly property color surface:         isDark ? "#131A26" : "#FFFFFF"
    readonly property color surfaceVariant:  isDark ? "#1C2333" : "#EEF1F5"
    readonly property color surfaceElevated: isDark ? "#1E293B" : "#FFFFFF"

    // --- Text ---
    readonly property color textPrimary:   isDark ? "#FFFFFF"  : "#1A1A2E"
    readonly property color textSecondary: isDark ? "#94A3B8"  : "#64748B"

    // --- Accent ---
    readonly property color accent:     isDark ? "#3B82F6" : "#2563EB"
    readonly property color accentSoft: isDark ? Qt.rgba(0.23, 0.51, 0.96, 0.12)
                                               : Qt.rgba(0.15, 0.39, 0.92, 0.08)

    // --- Semantic ---
    readonly property color success:     isDark ? "#22C55E" : "#16A34A"
    readonly property color successSoft: isDark ? "#163117" : "#DCFCE7"
    readonly property color danger:      isDark ? "#EF4444" : "#DC2626"
    readonly property color dangerSoft:  isDark ? "#2D1515" : "#FEE2E2"
    readonly property color warning:     isDark ? "#F59E0B" : "#D97706"

    // --- Borders & Dividers ---
    readonly property color border:  isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color divider: isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.05)

    // --- Cards & Containers ---
    readonly property color card:      isDark ? "#1E293B" : "#FFFFFF"
    readonly property color cardHover: isDark ? "#243244" : "#F0F4F8"

    // --- Overlays ---
    readonly property color overlay: isDark ? Qt.rgba(0, 0, 0, 0.6) : Qt.rgba(0, 0, 0, 0.3)

    // --- Specific Component Colors ---
    readonly property color tabBackground:       isDark ? "#1C2333" : "#E8ECF1"
    readonly property color tabSelected:         accent
    readonly property color tabSelectedText:     "#FFFFFF"
    readonly property color tabUnselectedText:   textSecondary
    readonly property color inputBackground:     isDark ? "#1C2333" : "#F0F2F5"
    readonly property color inputBorder:         isDark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.1)
    readonly property color inputFocusBorder:    accent
    readonly property color popupBackground:     isDark ? "#1E293B" : "#FFFFFF"
    readonly property color popupBorder:         isDark ? "#2D3A4F" : "#E2E8F0"
    readonly property color buttonSecondary:     isDark ? "#374151" : "#E5E7EB"
    readonly property color buttonSecondaryText: isDark ? "#D1D5DB" : "#374151"

    // --- Action Button (call screen) ---
    readonly property color actionButton:       isDark ? "#2D3748" : "#E2E8F0"
    readonly property color actionButtonActive:  accent

    // --- Status Indicator ---
    readonly property color statusOnline:  "#22C55E"
    readonly property color statusOffline: "#EF4444"
}
