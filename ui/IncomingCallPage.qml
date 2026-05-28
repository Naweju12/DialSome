import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: incomingCallPage
    anchors.fill: parent
    spacing: 0

    Rectangle {
        id: titleSection
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        Layout.topMargin: 80
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            spacing: 15

            Image {
                source: "../icons/user.png"
                sourceSize.width: 100
                sourceSize.height: 100
                Layout.alignment: Qt.AlignHCenter
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            Text {
                text: myBackend.callerName !== "" ? myBackend.callerName : "Unknown Caller"
                color: "#FFFFFF"
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 32
                font.bold: true
            }

            Text {
                text: "Incoming call..."
                color: "#B0B0B0"
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 16
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 60
        spacing: 30

        // 1. Swipe to Answer slider track
        Rectangle {
            id: slideTrack
            width: 320
            height: 72
            radius: 36
            color: Qt.rgba(255, 255, 255, 0.08)
            border.color: Qt.rgba(255, 255, 255, 0.12)
            border.width: 1

            // Shimmering instruction text
            Text {
                id: slideText
                text: "slide to answer"
                color: Qt.rgba(255, 255, 255, 0.6)
                font.pixelSize: 16
                font.letterSpacing: 1
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 20 // Offset right to center in the remaining track space

                // Smooth shimmering pulse animation
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
                color: "#4CAF50" // iOS-style Emerald Green

                Image {
                    source: "../icons/dial.png"
                    sourceSize.width: 32
                    sourceSize.height: 32
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                // Snap-back animation when released early
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
                        // Accept Call!
                        myBackend.acceptCall();
                    }
                }
            }
        }

        // 2. Decline Button Section
        ColumnLayout {
            spacing: 8
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                id: declineBtn
                color: "#F44336" // iOS-style Crimson Red
                height: 60
                width: 60
                radius: 30
                Layout.alignment: Qt.AlignHCenter

                Image {
                    source: "../icons/dial.png"
                    sourceSize.width: 32
                    sourceSize.height: 32
                    anchors.centerIn: parent
                    rotation: 135 // Turned down to hang up orientation
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        myBackend.endCall();
                    }
                    onPressed: declineBtn.color = "#D32F2F"
                    onReleased: declineBtn.color = "#F44336"
                }
            }

            Text {
                text: "Decline"
                color: "#B0B0B0"
                font.pixelSize: 13
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
