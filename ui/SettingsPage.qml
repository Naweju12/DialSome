import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: windowRoot
    color: "#000000"

    ColumnLayout {
        id: settingsPage
        anchors.fill: parent
        spacing: 0

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: myLayout.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: myLayout
                width: settingsPage.width
                spacing: 5

                // --- HEADER ---
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    color: "transparent"
                    Text {
                        text: "Settings"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 20
                        color: "white"
                        font.bold: true
                        font.pixelSize: 22
                    }
                }

                // --- SERVER ROW ---
                Rectangle {
                    id: serverRow
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    color: "transparent"

                    Rectangle {
                        anchors.fill: parent
                        color: "white"
                        opacity: serverMouseArea.pressed ? 0.1 : 0
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 15

                        Image {
                            source: "../icons/server.png"
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            fillMode: Image.PreserveAspectFit
                            sourceSize: Qt.size(64, 64)
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: "Server Configuration"
                                color: "white"
                                font.bold: true
                                font.pixelSize: 16
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: myBackend.serverUrl
                                    color: "#bdc3c7"
                                    font.pixelSize: 14
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    visible: myBackend.useHttps
                                    implicitWidth: 46
                                    implicitHeight: 18
                                    color: "#163117"
                                    border.color: "#4CAF50"
                                    radius: 4
                                    Text {
                                        anchors.centerIn: parent
                                        text: "HTTPS"
                                        color: "#4CAF50"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }

                                Rectangle {
                                    visible: myBackend.useWss
                                    implicitWidth: 38
                                    implicitHeight: 18
                                    color: "#0d2135"
                                    border.color: "#2196F3"
                                    radius: 4
                                    Text {
                                        anchors.centerIn: parent
                                        text: "WSS"
                                        color: "#2196F3"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: serverMouseArea
                        anchors.fill: parent
                        onClicked: serverPopup.open()
                    }
                }
            }
        }
    }

    // --- POPUP MODAL ---
    Popup {
        id: serverPopup
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: parent.height * 0.15
        width: parent.width * 0.9
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#2c3e50"
            radius: 16
            border.color: "#34495e"
            border.width: 2
        }

        contentItem: ColumnLayout {
            spacing: 20

            Text {
                text: "Edit Connection"
                color: "white"
                font.bold: true
                font.pixelSize: 20
                Layout.alignment: Qt.AlignHCenter
                bottomPadding: 5
            }

            TextField {
                id: serverInput
                placeholderText: "Enter Host/IP (e.g. 192.168.1.1)"
                text: myBackend.serverUrl
                Layout.fillWidth: true
                color: "white"

                // Allow letters, numbers, dots, and hyphens (basic URL/IP validation)
                validator: RegularExpressionValidator {
                    regularExpression: /[a-zA-Z0-9\.\-]+/
                }

                background: Rectangle {
                    implicitHeight: 48
                    color: "#34495e"
                    radius: 8
                    border.color: serverInput.activeFocus ? "#4CAF50" : "transparent"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Use Secure HTTPS"
                        color: "white"
                        Layout.fillWidth: true
                        font.pixelSize: 14
                    }
                    Switch {
                        id: httpsSwitch
                        checked: myBackend.useHttps
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Use WebSockets (WSS)"
                        color: "white"
                        Layout.fillWidth: true
                        font.pixelSize: 14
                    }
                    Switch {
                        id: wssSwitch
                        checked: myBackend.useWss
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Button {
                    text: "Cancel"
                    Layout.fillWidth: true
                    flat: true
                    onClicked: serverPopup.close()
                }

                Button {
                    id: saveBtn
                    text: "Save Changes"
                    Layout.fillWidth: true
                    highlighted: true

                    // Button is only enabled if input is not empty
                    enabled: serverInput.text.length > 0

                    background: Rectangle {
                        // Turns gray if disabled, green if enabled
                        color: !saveBtn.enabled ? "#555555" : (saveBtn.pressed ? "#388E3C" : "#4CAF50")
                        radius: 8
                        opacity: saveBtn.enabled ? 1.0 : 0.5
                    }

                    onClicked: {
                        myBackend.serverUrl = serverInput.text
                        myBackend.useHttps = httpsSwitch.checked
                        myBackend.useWss = wssSwitch.checked
                        serverPopup.close();
                    }
                }
            }
        }
    }
}
