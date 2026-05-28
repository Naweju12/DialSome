import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: selectContactPage
    anchors.fill: parent
    color: "#000000"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 20

        // Header Section
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            spacing: 15

            // Back button
            Rectangle {
                width: 40
                height: 40
                radius: 20
                color: "#1e1e1e"

                Image {
                    source: "../icons/dial.png" // We can rotate the dial icon to act as a back arrow or clean icon
                    sourceSize: Qt.size(20, 20)
                    anchors.centerIn: parent
                    rotation: -135 // Rotate the dial phone icon to look like a back arrow/pointing left
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mainStack.pop()
                }
            }

            Text {
                text: "Add Participant"
                color: "white"
                font.pixelSize: 22
                font.bold: true
                Layout.fillWidth: true
            }
        }

        // Search/Filter Bar
        TextField {
            id: searchBar
            placeholderText: "Search contacts..."
            Layout.fillWidth: true
            color: "white"
            placeholderTextColor: "#808080"
            font.pixelSize: 15

            background: Rectangle {
                implicitHeight: 45
                color: "#121212"
                radius: 8
                border.color: searchBar.activeFocus ? "#5B89F7" : "#333333"
                border.width: 1
            }
        }

        // Contacts list
        ListView {
            id: selectContactsView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: myBackend.contacts

            delegate: ItemDelegate {
                width: selectContactsView.width

                // Filter logic
                visible: modelData.name.toLowerCase().indexOf(searchBar.text.toLowerCase()) !== -1 ||
                         modelData.email.toLowerCase().indexOf(searchBar.text.toLowerCase()) !== -1
                height: visible ? 70 : 0

                background: Rectangle {
                    color: parent.pressed ? "#222222" : "transparent"
                    radius: 8
                }

                contentItem: RowLayout {
                    spacing: 15
                    anchors.fill: parent
                    anchors.margins: 10

                    Rectangle {
                        width: 45
                        height: 45
                        radius: 22.5
                        color: "#1e1e1e"

                        Image {
                            source: "../icons/user.png"
                            anchors.centerIn: parent
                            sourceSize: Qt.size(45, 45)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Text {
                            text: modelData.name
                            color: "white"
                            font.bold: true
                            font.pixelSize: 15
                        }
                        
                        Text {
                            text: modelData.email
                            color: "#808080"
                            font.pixelSize: 12
                        }
                    }

                    // Dial icon
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: "#27ae60"

                        Image {
                            source: "../icons/dial.png"
                            sourceSize: Qt.size(16, 16)
                            anchors.centerIn: parent
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                }

                onClicked: {
                    myBackend.dialNewParticipant(modelData.email);
                    mainStack.pop(); // Go back to CallingPage
                }
            }
        }
    }
}
