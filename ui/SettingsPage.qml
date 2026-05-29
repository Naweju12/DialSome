import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: windowRoot
    color: Theme.background

    Behavior on color {
        ColorAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    function handleBack() {
        if (serverPopup.opened) {
            serverPopup.close()
            return true
        }
        return false
    }

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
                spacing: 12

                // --- HEADER ---
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    Layout.leftMargin: 12
                    Layout.rightMargin: 16
                    spacing: 12

                    // Back button
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 10
                        color: backArea.pressed ? Theme.cardHover : Theme.surfaceVariant
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "‹"
                            color: Theme.textPrimary
                            font.pixelSize: 24
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: backArea
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
                        text: "Settings"
                        color: Theme.textPrimary
                        font.weight: Font.DemiBold
                        font.pixelSize: 22
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                // --- APPEARANCE SECTION ---
                Text {
                    text: "APPEARANCE"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                    Layout.leftMargin: 20
                    Layout.topMargin: 8
                }

                // Theme Toggle Row
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    radius: 16
                    color: Theme.card
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 14

                        // Moon/Sun icon
                        Rectangle {
                            width: 40
                            height: 40
                            radius: 12
                            color: Theme.accentSoft

                            Text {
                                text: Theme.isDark ? "🌙" : "☀️"
                                font.pixelSize: 20
                                anchors.centerIn: parent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: "Dark Mode"
                                color: Theme.textPrimary
                                font.weight: Font.DemiBold
                                font.pixelSize: 16
                            }

                            Text {
                                text: Theme.isDark ? "Dark theme active" : "Light theme active"
                                color: Theme.textSecondary
                                font.pixelSize: 13
                            }
                        }

                        Switch {
                            id: themeSwitch
                            onToggled: Theme.toggleTheme()

                            Binding on checked {
                                value: Theme.isDark
                            }
                        }
                    }
                }

                // --- CONNECTION SECTION ---
                Text {
                    text: "CONNECTION"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                    Layout.leftMargin: 20
                    Layout.topMargin: 16
                }

                // Server Configuration Row
                Rectangle {
                    id: serverRow
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    radius: 16
                    color: Theme.card
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 14

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 12
                            color: Theme.accentSoft

                            ThemedIcon {
                                source: "../icons/server.png"
                                iconColor: Theme.accent
                                sourceSize: Qt.size(22, 22)
                                width: 22; height: 22
                                anchors.centerIn: parent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: "Server Configuration"
                                color: Theme.textPrimary
                                font.weight: Font.DemiBold
                                font.pixelSize: 16
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: myBackend.serverUrl
                                    color: Theme.textSecondary
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    visible: myBackend.useHttps
                                    implicitWidth: 48
                                    implicitHeight: 20
                                    color: Theme.successSoft
                                    border.color: Theme.success
                                    border.width: 1
                                    radius: 6

                                    Text {
                                        anchors.centerIn: parent
                                        text: "HTTPS"
                                        color: Theme.success
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Rectangle {
                                    visible: myBackend.useWss
                                    implicitWidth: 40
                                    implicitHeight: 20
                                    color: Theme.accentSoft
                                    border.color: Theme.accent
                                    border.width: 1
                                    radius: 6

                                    Text {
                                        anchors.centerIn: parent
                                        text: "WSS"
                                        color: Theme.accent
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }

                        // Chevron
                        Text {
                            text: "›"
                            color: Theme.textSecondary
                            font.pixelSize: 22
                        }
                    }

                    MouseArea {
                        id: serverMouseArea
                        anchors.fill: parent
                        onClicked: serverPopup.open()
                        onPressed: parent.color = Theme.cardHover
                        onReleased: parent.color = Theme.card
                    }
                }

                // --- ABOUT SECTION ---
                Text {
                    text: "ABOUT"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                    Layout.leftMargin: 20
                    Layout.topMargin: 16
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    radius: 16
                    color: Theme.card
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 14

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 12
                            color: Theme.accentSoft

                            Image {
                                source: "../icons/logo.png"
                                sourceSize: Qt.size(22, 22)
                                anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "DialSome"
                                color: Theme.textPrimary
                                font.weight: Font.DemiBold
                                font.pixelSize: 16
                            }

                            Text {
                                text: "Version " + myBackend.appVersion
                                color: Theme.textSecondary
                                font.pixelSize: 13
                            }
                        }
                    }
                }

                // Bottom spacer
                Item {
                    Layout.preferredHeight: 30
                }
            }
        }
    }

    // --- SERVER EDIT POPUP ---
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
            color: Theme.popupBackground
            radius: 20
            border.color: Theme.popupBorder
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 20

            Text {
                text: "Edit Connection"
                color: Theme.textPrimary
                font.weight: Font.DemiBold
                font.pixelSize: 20
                Layout.alignment: Qt.AlignHCenter
                bottomPadding: 5
            }

            TextField {
                id: serverInput
                placeholderText: "Enter Host/IP (e.g. 192.168.1.1)"
                placeholderTextColor: Theme.textSecondary
                text: myBackend.serverUrl
                Layout.fillWidth: true
                color: Theme.textPrimary
                font.pixelSize: 14

                validator: RegularExpressionValidator {
                    regularExpression: /[a-zA-Z0-9\.\-:]+/
                }

                background: Rectangle {
                    implicitHeight: 48
                    color: Theme.inputBackground
                    radius: 12
                    border.color: serverInput.activeFocus ? Theme.inputFocusBorder : Theme.inputBorder
                    border.width: 1
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Use Secure HTTPS"
                        color: Theme.textPrimary
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
                        color: Theme.textPrimary
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

                // Cancel button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 10
                    color: cancelServerArea.pressed ? Theme.cardHover : Theme.buttonSecondary

                    Text {
                        text: "Cancel"
                        color: Theme.buttonSecondaryText
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: cancelServerArea
                        anchors.fill: parent
                        onClicked: serverPopup.close()
                    }
                }

                // Save button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 10
                    color: !saveBtnEnabled ? Theme.buttonSecondary
                         : saveServerArea.pressed ? Qt.darker(Theme.success, 1.2)
                         : Theme.success
                    opacity: saveBtnEnabled ? 1.0 : 0.5

                    property bool saveBtnEnabled: serverInput.text.length > 0

                    Text {
                        text: "Save Changes"
                        color: parent.saveBtnEnabled ? "#FFFFFF" : Theme.textSecondary
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: saveServerArea
                        anchors.fill: parent
                        enabled: parent.saveBtnEnabled
                        onClicked: {
                            myBackend.serverUrl = serverInput.text
                            myBackend.useHttps = httpsSwitch.checked
                            myBackend.useWss = wssSwitch.checked
                            serverPopup.close();
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }
        }
    }
}
