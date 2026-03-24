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

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 60
        spacing: 80 // Space between the two buttons

        // ACCEPT BUTTON (Green)
        Rectangle {
            id: acceptCallBtn
            color: "#4CAF50" // Material Green
            height: 70
            width: 70
            radius: 35 // Make it a perfect circle

            // Optional: Add a pulse animation to draw attention
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation {
                    to: 0.7
                    duration: 800
                }
                NumberAnimation {
                    to: 1.0
                    duration: 800
                }
            }

            Image {
                source: "../icons/dial.png"
                sourceSize.width: 40
                sourceSize.height: 40
                anchors.centerIn: parent
                // 0 degree rotation points up/right (standard for accept)
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // Assuming you will add an acceptCall() method to your C++ backend
                    myBackend.acceptCall();
                }

                // Visual feedback on press
                onPressed: acceptCallBtn.color = "#388E3C"
                onReleased: acceptCallBtn.color = "#4CAF50"
            }
        }

        // 2. REJECT BUTTON (Red)
        Rectangle {
            id: endCallBtn
            color: "#F44336" // Material Red
            height: 70
            width: 70
            radius: 35

            Image {
                source: "../icons/dial.png"
                sourceSize.width: 40
                sourceSize.height: 40
                anchors.centerIn: parent
                rotation: 135 // Turned downwards to indicate hanging up
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    myBackend.endCall();
                }

                // Visual feedback on press
                onPressed: endCallBtn.color = "#D32F2F"
                onReleased: endCallBtn.color = "#F44336"
            }
        }
    }
}
