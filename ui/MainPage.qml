import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: mainPage
    spacing: 0

    Rectangle {
        id: titleSection
        Layout.fillWidth: true
        Layout.preferredHeight: 60

        color: "transparent"
        border.width: 1

        RowLayout {
            anchors.fill: parent

            Text {
                text: "DialSome"
                color: "#5B89F7"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                font.pixelSize: 18
            }

            Rectangle {
                width: 10
                height: 10
                color: myBackend.serverConnected ? "green" : "red"
                radius: width / 2

                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 2
            }

            Item {
                Layout.fillWidth: true
            }

            Image {
                id: settingsBtn
                source: "../icons/settings.png"
                sourceSize.width: 20
                sourceSize.height: 20

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        mainStack.push(settingsPageComponent)
                    }
                }
            }
        }
    }

    Rectangle {
        id: optionsSection
        Layout.fillWidth: true
        Layout.preferredHeight: 35
        color: "#121212"
        Layout.topMargin: 10
        radius: 8

        // 0 = Dialer, 1 = Recents, 2 = Contacts
        property int selectedIndex: 0

        RowLayout {
            anchors.fill: parent
            anchors.margins: 3

            Rectangle {
                id: optionsSectionFavourites
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: optionsSection.selectedIndex === 0 ? mainWindow.color : "transparent"
                radius: 5

                Text {
                    text: "Dialer"
                    color: optionsSection.selectedIndex === 0 ? "#5B89F7" : "white"
                    anchors.centerIn: parent

                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: optionsSection.selectedIndex = 0
                }

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }

            Rectangle {
                id: optionsSectionRecents
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: optionsSection.selectedIndex === 1 ? mainWindow.color : "transparent"
                radius: 5

                Text {
                    text: "Recents"
                    color: optionsSection.selectedIndex === 1 ? "#5B89F7" : "white"
                    anchors.centerIn: parent

                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: optionsSection.selectedIndex = 1
                }

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }

            Rectangle {
                id: optionsSectionContacts
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: optionsSection.selectedIndex === 2 ? mainWindow.color : "transparent"
                radius: 5

                Text {
                    text: "Contacts"
                    color: optionsSection.selectedIndex === 2 ? "#5B89F7" : "white"
                    anchors.centerIn: parent

                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: optionsSection.selectedIndex = 2
                }

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }
        }
    }

    Rectangle {
        id: mainSection
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "transparent"
        Layout.topMargin: 10

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20
            visible: optionsSection.selectedIndex === 0

            TextField {
                id: roomInput
                placeholderText: "Enter Email ID"
                color: "white"
                background: Rectangle { color: "#333"; radius: 5 }
                Layout.preferredWidth: 250
                Layout.alignment: Qt.AlignHCenter
            }

            Button {
                text: "Start Call"
                onClicked: {
                    if (roomInput.text.trim().length > 0) {
                        myBackend.startCall(roomInput.text.trim())
                    }
                }
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: myBackend.message
                color: "#5B89F7"
                font.pixelSize: 14
                Layout.alignment: Qt.AlignHCenter
            }
        }

        ListView {
            id: recentsView
            anchors.fill: parent
            visible: optionsSection.selectedIndex === 1
            model: myBackend.recentCalls
            clip: true

            delegate: ItemDelegate {
                width: recentsView.width
                height: 70

                background: Rectangle {
                    color: parent.pressed ? "#222" : "transparent"
                }

                contentItem: RowLayout {
                    spacing: 15
                    Rectangle {
                        width: 45; height: 45; radius: 22.5; color: "#333"
                        Image {
                            source: "../icons/user.png"
                            anchors.centerIn: parent
                            sourceSize: Qt.size(45, 45)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }
                    ColumnLayout {
                        Text {
                            text: modelData.name
                            color: "white"
                            font.bold: true
                        }
                        Text {
                            text: (modelData.isIncoming ? "Incoming" : "Outgoing") + " • " + modelData.email
                            color: "#808080"
                            font.pixelSize: 12
                        }
                    }
                }
                onClicked: {
                    // Re-dial the person directly from recents
                    myBackend.startCall(modelData.email)
                }
            }
        }
    }

    // Push everything to the top
    Item {
        Layout.fillHeight: true
    }
}
