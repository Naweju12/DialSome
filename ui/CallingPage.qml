import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: callPage
    anchors.fill: parent
    spacing: 0

    property int callDuration: 0

    function formatDuration(seconds) {
        var hours = Math.floor(seconds / 3600)
        var mins = Math.floor((seconds % 3600) / 60)
        var secs = seconds % 60
        
        var timeStr = ""
        if (hours > 0) {
            timeStr += hours + ":" + (mins < 10 ? "0" : "")
        }
        timeStr += mins + ":" + (secs < 10 ? "0" : "") + secs
        return timeStr
    }

    Timer {
        id: callTimer
        interval: 1000
        running: myBackend.callConnected
        repeat: true
        onTriggered: {
            callDuration += 1
        }
    }

    Connections {
        target: myBackend
        function onCallConnectedChanged() {
            if (!myBackend.callConnected) {
                callDuration = 0
            }
        }
    }

    Rectangle {
        id: titleSection
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        Layout.topMargin: 50

        color: "transparent"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent

            Image {
                source: "../icons/user.png"
                sourceSize.width: 80
                sourceSize.height: 80
                Layout.alignment: Qt.AlignHCenter

                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            Text {
                text: myBackend.callerName
                color: "#FFFFFF"
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: myBackend.callerName.indexOf(",") !== -1 ? 18 : 30
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.preferredWidth: parent.width * 0.9
            }

            Text {
                text: myBackend.message
                color: "#808080"
                Layout.alignment: Qt.AlignHCenter

                font.pixelSize: 15
            }

            Text {
                text: callPage.formatDuration(callPage.callDuration)
                color: "#2ecc71" // Emerald green call active color
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 18
                font.bold: true
                visible: myBackend.callConnected
            }
        }
    }

    // Push everything to the top
    Item {
        Layout.fillHeight: true
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 25
        spacing: 25

        // Speaker Toggle Button
        Rectangle {
            id: speakerBtn
            color: myBackend.speakerOn ? "#FFFFFF" : "#4A4A4A"
            height: 60
            width: height
            radius: height / 2

            Image {
                // Dynamically change the icon based on the state
                source: myBackend.speakerOn ? "../icons/volume_on.png" : "../icons/volume_off.png"
                sourceSize.width: 30
                sourceSize.height: 30
                anchors.centerIn: parent

                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    myBackend.setSpeakerOn(!myBackend.speakerOn);
                }
            }
        }

        // Microphone Mute Button
        Rectangle {
            id: micMuteBtn
            color: myBackend.micMuted ? "#FFFFFF" : "#4A4A4A"
            height: 60
            width: height
            radius: height / 2

            Image {
                source: myBackend.micMuted ? "../icons/mic_off.png" : "../icons/mic_on.png"
                sourceSize.width: 30
                sourceSize.height: 30
                anchors.centerIn: parent

                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    myBackend.setMicMuted(!myBackend.micMuted);
                }
            }
        }

        // Add Call (Invite) Button
        Rectangle {
            id: addCallBtn
            color: "#4A4A4A"
            height: 60
            width: height
            radius: height / 2

            Image {
                source: "../icons/add.png"
                sourceSize.width: 30
                sourceSize.height: 30
                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    mainStack.push(selectContactPageComponent);
                }
            }
        }

        // End Call Button
        Rectangle {
            id: endCallBtn
            color: "red"
            height: 60
            width: height
            radius: height / 2

            Image {
                source: "../icons/dial.png"
                sourceSize.width: 35
                sourceSize.height: 35
                anchors.centerIn: parent
                rotation: 135
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    myBackend.endCall();
                }
            }
        }
    }

    // Merge Call Button (visible only when there are held peers)
    Rectangle {
        id: mergeCallBtn
        visible: myBackend.hasHeldPeers
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 30
        height: 48
        width: 180
        radius: 24
        color: "#27ae60" // Beautiful green color for merging

        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            
            Image {
                source: "../icons/dial.png"
                sourceSize: Qt.size(18, 18)
                fillMode: Image.PreserveAspectFit
            }
            
            Text {
                text: "Merge Call"
                color: "white"
                font.bold: true
                font.pixelSize: 14
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                myBackend.mergeCalls();
                myUtils.showToast("Calls merged successfully!");
            }
        }
    }
}
