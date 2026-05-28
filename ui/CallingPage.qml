import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

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
                    invitePopup.open();
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

    Popup {
        id: invitePopup
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: parent.height * 0.25
        width: parent.width * 0.9
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#1e1e1e"
            radius: 16
            border.color: "#333333"
            border.width: 2
        }

        contentItem: ColumnLayout {
            spacing: 20
            
            Text {
                text: "Invite to Group Call"
                color: "white"
                font.bold: true
                font.pixelSize: 18
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: inviteEmailInput
                placeholderText: "Enter Email Address"
                Layout.fillWidth: true
                color: "white"
                placeholderTextColor: "#808080"
                font.pixelSize: 15

                background: Rectangle {
                    implicitHeight: 48
                    color: "#2a2a2a"
                    radius: 8
                    border.color: inviteEmailInput.activeFocus ? "#5B89F7" : "#444444"
                    border.width: 1
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Button {
                    text: "Cancel"
                    Layout.fillWidth: true
                    flat: true
                    
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: parent.pressed ? "#333333" : "transparent"
                        radius: 8
                    }

                    onClicked: {
                        inviteEmailInput.text = "";
                        invitePopup.close();
                    }
                }

                Button {
                    id: inviteSubmitBtn
                    text: "Invite"
                    Layout.fillWidth: true
                    enabled: inviteEmailInput.text.trim().length > 0

                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? "white" : "#808080"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: !parent.enabled ? "#333333" : (parent.pressed ? "#4477ee" : "#5B89F7")
                        radius: 8
                        opacity: parent.enabled ? 1.0 : 0.5
                    }

                    onClicked: {
                        myBackend.inviteToCall(inviteEmailInput.text.trim());
                        myUtils.showToast("Inviting " + inviteEmailInput.text.trim() + "...");
                        inviteEmailInput.text = "";
                        invitePopup.close();
                    }
                }
            }
        }
    }
}
