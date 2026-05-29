import QtQuick
import Qt5Compat.GraphicalEffects

/**
 * ThemedIcon — A reusable component that renders a monochrome PNG icon
 * and tints it to the specified color using ColorOverlay.
 * This makes white/light icons visible on light backgrounds and vice versa.
 *
 * Usage:
 *   ThemedIcon {
 *       source: "../icons/settings.png"
 *       iconColor: Theme.textPrimary
 *       sourceSize: Qt.size(18, 18)
 *   }
 */
Item {
    id: root

    property alias source: img.source
    property alias sourceSize: img.sourceSize
    property alias fillMode: img.fillMode
    property alias smooth: img.smooth
    property alias mipmap: img.mipmap

    // The tint color for the icon (adapts per theme)
    property color iconColor: Theme.textPrimary

    implicitWidth: img.implicitWidth
    implicitHeight: img.implicitHeight

    Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        smooth: true
        
        layer.enabled: true
        layer.effect: ColorOverlay {
            color: root.iconColor
        }
    }
}
