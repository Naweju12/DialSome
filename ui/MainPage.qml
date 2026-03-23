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
                id: addContactBtn
                source: "../icons/add.png"
                sourceSize.width: 30
                sourceSize.height: 30
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                visible: optionsSection.selectedIndex === 2

                MouseArea {
                    anchors.fill: parent
                    onClicked: addContactPopup.open()
                }
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

        ListView {
            id: contactsView
            anchors.fill: parent
            visible: optionsSection.selectedIndex === 2
            model: myBackend.contacts
            clip: true

            delegate: ItemDelegate {
                width: contactsView.width
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
                            text: modelData.email
                            color: "#808080"
                            font.pixelSize: 12
                        }
                    }
                }
                onClicked: {
                    // Call the person directly from contacts
                    myBackend.startCall(modelData.email)
                }
            }
        }
    }

    // Push everything to the top
    Item {
        Layout.fillHeight: true
    }

    Popup {
        id: addContactPopup
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: parent.height * 0.15
        width: parent.width * 0.9
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside //

        background: Rectangle {
            color: "#2c3e50"
            radius: 16
            border.color: "#34495e"
            border.width: 2
        }

        contentItem: ColumnLayout {
            spacing: 20 //

            Text {
                text: "Add New Contact"
                color: "white"
                font.bold: true
                font.pixelSize: 20
                Layout.alignment: Qt.AlignHCenter
                bottomPadding: 5 //
            }

            TextField {
                id: contactEmailInput
                placeholderText: "Enter Email Address"
                Layout.fillWidth: true //
                color: "white"

                background: Rectangle {
                    implicitHeight: 48
                    color: "#34495e"
                    radius: 8
                    border.color: contactEmailInput.activeFocus ? "#4CAF50" : "transparent" //
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Button {
                    text: "Cancel"
                    Layout.fillWidth: true
                    flat: true
                    onClicked: {
                        contactEmailInput.text = "" // Clear the input
                        addContactPopup.close() //
                    }
                }

                Button {
                    id: addBtn
                    text: "Add"
                    Layout.fillWidth: true
                    highlighted: true

                    // Button is only enabled if input is not empty
                    enabled: contactEmailInput.text.trim().length > 0 //

                    background: Rectangle {
                        color: !addBtn.enabled ? "#555555" : (addBtn.pressed ? "#388E3C" : "#4CAF50") //
                        radius: 8
                        opacity: addBtn.enabled ? 1.0 : 0.5 //
                    }

                    onClicked: {
                        // Call backend function
                        myBackend.addContact(contactEmailInput.text.trim())

                        contactEmailInput.text = "" // clear upon submit
                        addContactPopup.close(); //
                    }
                }
            }
        }
    }
}
