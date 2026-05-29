import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: selectContactPage
    anchors.fill: parent
    color: Theme.background

    Behavior on color {
        ColorAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 16

        // --- HEADER ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            spacing: 12

            // Back button
            Rectangle {
                width: 40
                height: 40
                radius: 12
                color: backContactArea.pressed ? Theme.cardHover : Theme.surfaceVariant

                Text {
                    text: "‹"
                    color: Theme.textPrimary
                    font.pixelSize: 24
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: backContactArea
                    anchors.fill: parent
                    onClicked: mainStack.pop()
                    onPressed: parent.scale = 0.9
                    onReleased: parent.scale = 1.0
                }

                Behavior on scale {
                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                }
            }

            Text {
                text: "Add Participant"
                color: Theme.textPrimary
                font.pixelSize: 22
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
        }

        // --- SEARCH BAR ---
        TextField {
            id: searchBar
            placeholderText: "Search contacts..."
            Layout.fillWidth: true
            color: Theme.textPrimary
            placeholderTextColor: Theme.textSecondary
            font.pixelSize: 15

            background: Rectangle {
                implicitHeight: 48
                color: Theme.inputBackground
                radius: 12
                border.color: searchBar.activeFocus ? Theme.inputFocusBorder : Theme.inputBorder
                border.width: 1

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }
            }
        }

        // --- CONTACTS LIST ---
        ListView {
            id: selectContactsView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: myBackend.contacts
            spacing: 6

            delegate: ItemDelegate {
                width: selectContactsView.width

                // Filter logic
                visible: modelData.name.toLowerCase().indexOf(searchBar.text.toLowerCase()) !== -1 ||
                         modelData.email.toLowerCase().indexOf(searchBar.text.toLowerCase()) !== -1
                height: visible ? 72 : 0

                background: Rectangle {
                    color: parent.pressed ? Theme.cardHover : Theme.card
                    radius: 12
                    border.color: Theme.border
                    border.width: 1
                }

                contentItem: RowLayout {
                    spacing: 14
                    anchors.fill: parent
                    anchors.margins: 10

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: Theme.surfaceVariant

                        ThemedIcon {
                            source: "../icons/user.png"
                            iconColor: Theme.textSecondary
                            anchors.centerIn: parent
                            sourceSize: Qt.size(44, 44)
                            width: 44; height: 44
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: modelData.name
                            color: Theme.textPrimary
                            font.weight: Font.DemiBold
                            font.pixelSize: 15
                        }

                        Text {
                            text: modelData.email
                            color: Theme.textSecondary
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Dial action icon
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: Theme.success

                        ThemedIcon {
                            source: "../icons/dial.png"
                            iconColor: "#FFFFFF"
                            sourceSize: Qt.size(16, 16)
                            width: 16; height: 16
                            anchors.centerIn: parent
                        }

                        scale: dialIconArea.pressed ? 0.85 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                        }

                        MouseArea {
                            id: dialIconArea
                            anchors.fill: parent
                            onClicked: {
                                myBackend.dialNewParticipant(modelData.email);
                                mainStack.pop();
                            }
                        }
                    }
                }

                onClicked: {
                    myBackend.dialNewParticipant(modelData.email);
                    mainStack.pop();
                }
            }
        }
    }
}
