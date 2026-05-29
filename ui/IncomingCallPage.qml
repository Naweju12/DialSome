import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: incomingCallPage
    anchors.fill: parent
    spacing: 0

    function handleBack() {
        myBackend.endCall()
        return true
    }

    // --- CALLER INFO ---
    Rectangle {
        id: titleSection
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        Layout.topMargin: 80
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            spacing: 15

            // Avatar with animated pulsing ring
            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 110
                height: 110

                // Outer pulsing ring
                Rectangle {
                    id: pulseRing
                    anchors.centerIn: parent
                    width: 110
                    height: 110
                    radius: 55
                    color: "transparent"
                    border.color: Theme.success
                    border.width: 2
                    opacity: 0.4

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.3; duration: 1200; easing.type: Easing.OutQuad }
                        NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InQuad }
                    }

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 1200; easing.type: Easing.OutQuad }
                        NumberAnimation { to: 0.4; duration: 1200; easing.type: Easing.InQuad }
                    }
                }

                // Second pulse ring (offset timing)
                Rectangle {
                    anchors.centerIn: parent
                    width: 110
                    height: 110
                    radius: 55
                    color: "transparent"
                    border.color: Theme.success
                    border.width: 1.5
                    opacity: 0.3

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.5; duration: 1600; easing.type: Easing.OutQuad }
                        NumberAnimation { to: 1.0; duration: 1600; easing.type: Easing.InQuad }
                    }

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 1600; easing.type: Easing.OutQuad }
                        NumberAnimation { to: 0.3; duration: 1600; easing.type: Easing.InQuad }
                    }
                }

                // Avatar container
                Rectangle {
                    anchors.centerIn: parent
                    width: 100
                    height: 100
                    radius: 50
                    color: Theme.surfaceVariant
                    border.color: Theme.border
                    border.width: 1

                    Image {
                        source: "../icons/user.png"
                        sourceSize: Qt.size(100, 100)
                        width: 100; height: 100
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }
            }

            Text {
                text: myBackend.callerName !== "" ? myBackend.callerName : "Unknown Caller"
                color: Theme.textPrimary
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 30
                font.weight: Font.DemiBold
            }

            Text {
                text: "Incoming call..."
                color: Theme.textSecondary
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 16
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }

    // --- ANSWER / DECLINE ---
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 60
        spacing: 30

        // Swipe to Answer slider track
        Rectangle {
            id: slideTrack
            width: 320
            height: 72
            radius: 36
            color: Theme.surfaceVariant
            border.color: Theme.border
            border.width: 1
            Layout.alignment: Qt.AlignHCenter

            // Shimmering instruction text
            Text {
                id: slideText
                text: "slide to answer"
                color: Theme.textSecondary
                font.pixelSize: 16
                font.letterSpacing: 1
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 20

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 1200; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.8; duration: 1200; easing.type: Easing.InOutSine }
                }
            }

            // Green slide handle
            Rectangle {
                id: slideHandle
                x: 4
                y: 4
                width: 64
                height: 64
                radius: 32
                color: Theme.success

                ThemedIcon {
                    source: "../icons/dial.png"
                    iconColor: "#FFFFFF"
                    sourceSize: Qt.size(32, 32)
                    width: 32; height: 32
                    anchors.centerIn: parent
                }

                Behavior on x {
                    id: snapBackBehavior
                    enabled: !dragArea.drag.active
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                drag.target: slideHandle
                drag.axis: Drag.XAxis
                drag.minimumX: 4
                drag.maximumX: slideTrack.width - slideHandle.width - 4

                onReleased: {
                    if (slideHandle.x >= drag.maximumX - 8) {
                        myBackend.acceptCall();
                    }
                }
            }
        }

        // Decline Button
        ColumnLayout {
            spacing: 8
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                id: declineBtn
                color: declineArea.pressed ? Qt.darker(Theme.danger, 1.2) : Theme.danger
                height: 60
                width: 60
                radius: 30
                Layout.alignment: Qt.AlignHCenter

                ThemedIcon {
                    source: "../icons/dial.png"
                    iconColor: "#FFFFFF"
                    sourceSize: Qt.size(32, 32)
                    width: 32; height: 32
                    anchors.centerIn: parent
                    rotation: 135
                }

                MouseArea {
                    id: declineArea
                    anchors.fill: parent
                    onClicked: myBackend.endCall()
                    onPressed: parent.scale = 0.9
                    onReleased: parent.scale = 1.0
                }

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
                Behavior on scale {
                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                }
            }

            Text {
                text: "Decline"
                color: Theme.textSecondary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
