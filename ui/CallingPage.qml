import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: callPage
    anchors.fill: parent
    spacing: 0

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

                font.pixelSize: 30
            }

            Text {
                text: myBackend.message
                color: "#808080"
                Layout.alignment: Qt.AlignHCenter

                font.pixelSize: 15
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
        spacing: 40

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
}
