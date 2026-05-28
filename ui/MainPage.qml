import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: mainPage
    spacing: 0

    property string selectedContactName: ""
    property string selectedContactEmail: ""

    // --- HEADER ---
    Rectangle {
        id: titleSection
        Layout.fillWidth: true
        Layout.preferredHeight: 60
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            spacing: 10

            Text {
                text: "DialSome"
                color: Theme.accent
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                font.pixelSize: 22
                font.weight: Font.DemiBold
            }

            Rectangle {
                width: 10
                height: 10
                color: myBackend.serverConnected ? Theme.statusOnline : Theme.statusOffline
                radius: width / 2

                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 2

                // Pulse animation for online status
                SequentialAnimation on scale {
                    running: myBackend.serverConnected
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.3; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Add Contact button
            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: Theme.surfaceVariant
                visible: optionsSection.selectedIndex === 2
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36

                Image {
                    id: addContactBtn
                    source: "../icons/add.png"
                    sourceSize.width: 20
                    sourceSize.height: 20
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: addContactPopup.open()
                    onPressed: parent.scale = 0.9
                    onReleased: parent.scale = 1.0
                }

                Behavior on scale {
                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                }
            }

            // Settings button
            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: Theme.surfaceVariant
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36

                Image {
                    id: settingsBtn
                    source: "../icons/settings.png"
                    sourceSize.width: 18
                    sourceSize.height: 18
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        mainStack.push(settingsPageComponent)
                    }
                    onPressed: parent.scale = 0.9
                    onReleased: parent.scale = 1.0
                }

                Behavior on scale {
                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    // Subtle header divider
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Theme.divider
    }

    // --- TAB BAR ---
    Rectangle {
        id: optionsSection
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        color: Theme.tabBackground
        Layout.topMargin: 12
        radius: 12

        // 0 = Dialer, 1 = Recents, 2 = Contacts
        property int selectedIndex: 0

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4

            Repeater {
                model: ["Dialer", "Recents", "Contacts"]

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: optionsSection.selectedIndex === index ? Theme.accent : "transparent"
                    radius: 8

                    Text {
                        text: modelData
                        color: optionsSection.selectedIndex === index ? Theme.tabSelectedText : Theme.tabUnselectedText
                        anchors.centerIn: parent
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: optionsSection.selectedIndex = index
                    }

                    Behavior on color {
                        ColorAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }

                    // Subtle scale pop on selection
                    scale: optionsSection.selectedIndex === index ? 1.0 : 0.98
                    Behavior on scale {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }

    // --- MAIN CONTENT ---
    Rectangle {
        id: mainSection
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "transparent"
        Layout.topMargin: 16

        // ===== DIALER TAB =====
        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20
            spacing: 20
            visible: optionsSection.selectedIndex === 0

            TextField {
                id: roomInput
                placeholderText: "Enter Email(s), comma-separated"
                placeholderTextColor: Theme.textSecondary
                color: Theme.textPrimary
                font.pixelSize: 14
                background: Rectangle {
                    implicitHeight: 48
                    color: Theme.inputBackground
                    radius: 12
                    border.color: roomInput.activeFocus ? Theme.inputFocusBorder : Theme.inputBorder
                    border.width: 1

                    Behavior on border.color {
                        ColorAnimation { duration: 200 }
                    }
                }
                Layout.preferredWidth: 280
                Layout.alignment: Qt.AlignHCenter
            }

            // Start Call button — modern styled
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 280
                Layout.preferredHeight: 48
                radius: 12
                color: startCallArea.pressed ? Qt.darker(Theme.accent, 1.2) : Theme.accent

                Text {
                    text: "Start Call"
                    color: "#FFFFFF"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: startCallArea
                    anchors.fill: parent
                    onClicked: {
                        if (roomInput.text.trim().length > 0) {
                            myBackend.startCall(roomInput.text.trim())
                        }
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                scale: startCallArea.pressed ? 0.97 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                }
            }

            Text {
                text: myBackend.message
                color: Theme.accent
                font.pixelSize: 14
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // ===== RECENTS TAB =====
        ListView {
            id: recentsView
            anchors.fill: parent
            visible: optionsSection.selectedIndex === 1
            model: myBackend.recentCalls
            clip: true
            spacing: 6

            delegate: ItemDelegate {
                width: recentsView.width
                height: 72

                background: Rectangle {
                    color: parent.pressed ? Theme.cardHover : Theme.card
                    radius: 12
                    border.color: Theme.border
                    border.width: 1
                }

                contentItem: RowLayout {
                    spacing: 14
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Rectangle {
                        width: 44; height: 44; radius: 22
                        color: Theme.surfaceVariant
                        Image {
                            source: "../icons/user.png"
                            anchors.centerIn: parent
                            sourceSize: Qt.size(44, 44)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
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
                            text: (modelData.isIncoming ? "Incoming" : "Outgoing") + " • " + modelData.email
                            color: Theme.textSecondary
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Call action hint
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: Theme.accentSoft
                        Image {
                            source: "../icons/dial.png"
                            sourceSize: Qt.size(16, 16)
                            anchors.centerIn: parent
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                }

                onClicked: {
                    myBackend.startCall(modelData.email)
                }
            }
        }

        // ===== CONTACTS TAB =====
        ListView {
            id: contactsView
            anchors.fill: parent
            visible: optionsSection.selectedIndex === 2
            model: myBackend.contacts
            clip: true
            spacing: 6

            delegate: ItemDelegate {
                width: contactsView.width
                height: 72

                background: Rectangle {
                    color: parent.pressed ? Theme.cardHover : Theme.card
                    radius: 12
                    border.color: Theme.border
                    border.width: 1
                }

                contentItem: RowLayout {
                    spacing: 14
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Rectangle {
                        width: 44; height: 44; radius: 22
                        color: Theme.surfaceVariant
                        Image {
                            source: "../icons/user.png"
                            anchors.centerIn: parent
                            sourceSize: Qt.size(44, 44)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            spacing: 8
                            Text {
                                text: modelData.name
                                color: Theme.textPrimary
                                font.weight: Font.DemiBold
                                font.pixelSize: 15
                            }
                            
                            Rectangle {
                                visible: myBackend.blockedUsers.indexOf(modelData.email) !== -1
                                implicitWidth: 50
                                implicitHeight: 18
                                color: Theme.dangerSoft
                                border.color: Theme.danger
                                border.width: 1
                                radius: 4
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "Blocked"
                                    color: Theme.danger
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        Text {
                            text: modelData.email
                            color: Theme.textSecondary
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Call action icon
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: Theme.accentSoft
                        Image {
                            source: "../icons/dial.png"
                            sourceSize: Qt.size(16, 16)
                            anchors.centerIn: parent
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                }

                onClicked: {
                    selectedContactName = modelData.name
                    selectedContactEmail = modelData.email
                    contactDetailsPopup.open()
                }
            }
        }
    }

    // Push everything to the top
    Item {
        Layout.fillHeight: true

        Dialog {
            id: fullScreenPermissionDialog
            title: "Permission Required"
            standardButtons: Dialog.Ok | Dialog.Cancel
            anchors.centerIn: Overlay.overlay
            modal: true

            Label {
                text: "To receive incoming calls while your phone is locked, DialSome needs Full-Screen Alert permissions."
                wrapMode: Label.WordWrap
                width: 300
            }

            onAccepted: {
                myBackend.requestFullScreenIntentPermission();
            }
        }

        Component.onCompleted: {
            if (!myBackend.canUseFullScreenIntent()) {
                fullScreenPermissionDialog.open();
            }
        }
    }

    // --- ADD CONTACT POPUP ---
    Popup {
        id: addContactPopup
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
                text: "Add New Contact"
                color: Theme.textPrimary
                font.weight: Font.DemiBold
                font.pixelSize: 20
                Layout.alignment: Qt.AlignHCenter
                bottomPadding: 5
            }

            TextField {
                id: contactEmailInput
                placeholderText: "Enter Email Address"
                placeholderTextColor: Theme.textSecondary
                Layout.fillWidth: true
                color: Theme.textPrimary
                font.pixelSize: 14

                background: Rectangle {
                    implicitHeight: 48
                    color: Theme.inputBackground
                    radius: 12
                    border.color: contactEmailInput.activeFocus ? Theme.inputFocusBorder : Theme.inputBorder
                    border.width: 1
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
                    color: cancelContactArea.pressed ? Theme.cardHover : Theme.buttonSecondary

                    Text {
                        text: "Cancel"
                        color: Theme.buttonSecondaryText
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: cancelContactArea
                        anchors.fill: parent
                        onClicked: {
                            contactEmailInput.text = ""
                            addContactPopup.close()
                        }
                    }
                }

                // Add button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 10
                    color: !addBtnEnabled ? Theme.buttonSecondary
                         : addContactArea.pressed ? Qt.darker(Theme.success, 1.2)
                         : Theme.success
                    opacity: addBtnEnabled ? 1.0 : 0.5

                    property bool addBtnEnabled: contactEmailInput.text.trim().length > 0

                    Text {
                        text: "Add"
                        color: parent.addBtnEnabled ? "#FFFFFF" : Theme.textSecondary
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: addContactArea
                        anchors.fill: parent
                        enabled: parent.addBtnEnabled
                        onClicked: {
                            myBackend.addContact(contactEmailInput.text.trim())
                            contactEmailInput.text = ""
                            addContactPopup.close();
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }
        }
    }

    // --- IPHONE-STYLE CONTACT DETAILS POPUP ---
    Popup {
        id: contactDetailsPopup
        parent: Overlay.overlay
        x: 0
        y: parent.height - height
        width: parent.width
        height: parent.height * 0.72 // iPhone style 3/4 height sheet
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        enter: Transition {
            NumberAnimation { property: "y"; from: parent.height; to: parent.height - height; duration: 300; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "y"; from: parent.height - height; to: parent.height; duration: 250; easing.type: Easing.InCubic }
        }

        background: Rectangle {
            color: Theme.popupBackground
            radius: 24
            // iOS Bottom Sheet only rounds top corners
            clip: true
            Rectangle {
                width: parent.width
                height: 24
                color: Theme.popupBackground
                anchors.bottom: parent.bottom
            }
            border.color: Theme.popupBorder
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 20
            anchors.margins: 20

            // Top Drag Handle (iOS style pill)
            Rectangle {
                width: 36
                height: 5
                radius: 2.5
                color: Theme.divider
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -8
            }

            // --- AVATAR CIRCLE ---
            Rectangle {
                width: 80
                height: 80
                radius: 40
                color: Theme.accentSoft
                Layout.alignment: Qt.AlignHCenter

                Text {
                    text: selectedContactName.length > 0 ? selectedContactName.charAt(0).toUpperCase() : "?"
                    color: Theme.accent
                    font.pixelSize: 32
                    font.weight: Font.Bold
                    anchors.centerIn: parent
                }
            }

            // --- NAME & EMAIL ---
            ColumnLayout {
                spacing: 4
                Layout.alignment: Qt.AlignHCenter

                Text {
                    text: selectedContactName
                    color: Theme.textPrimary
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: selectedContactEmail
                    color: Theme.textSecondary
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // --- QUICK ACTION CONTAINER ---
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 24

                ColumnLayout {
                    spacing: 6
                    Layout.alignment: Qt.AlignHCenter

                    Rectangle {
                        id: detailsCallBtn
                        width: 50
                        height: 50
                        radius: 25
                        color: Theme.accent

                        Image {
                            source: "../icons/dial.png"
                            sourceSize: Qt.size(20, 20)
                            anchors.centerIn: parent
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                contactDetailsPopup.close()
                                myBackend.startCall(selectedContactEmail)
                            }
                            onPressed: parent.scale = 0.9
                            onReleased: parent.scale = 1.0
                        }

                        Behavior on scale {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        text: "Call"
                        color: Theme.accent
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // --- DETAILS CARD SECTION ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 16
                color: Theme.card
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14

                    Text {
                        text: "Quick Info"
                        color: Theme.textPrimary
                        font.weight: Font.DemiBold
                        font.pixelSize: 13
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Available for voice calls"
                        color: Theme.textSecondary
                        font.pixelSize: 12
                    }
                }
            }

            // --- iOS STYLE DANGER ACTION SECTION ---
            Rectangle {
                id: blockToggleBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 16
                color: Theme.card
                border.color: Theme.border
                border.width: 1

                property bool isBlocked: myBackend.blockedUsers.indexOf(selectedContactEmail) !== -1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14

                    Text {
                        text: blockToggleBtn.isBlocked ? "Unblock this Caller" : "Block this Caller"
                        color: blockToggleBtn.isBlocked ? Theme.success : Theme.danger
                        font.weight: Font.DemiBold
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (myBackend.blockedUsers.indexOf(selectedContactEmail) !== -1) {
                            myBackend.unblockUser(selectedContactEmail)
                            myUtils.showToast("Contact unblocked successfully")
                        } else {
                            myBackend.blockUser(selectedContactEmail)
                            myUtils.showToast("Contact blocked successfully")
                        }
                    }
                    onPressed: parent.color = Theme.cardHover
                    onReleased: parent.color = Theme.card
                }
            }

            // Done/Close Button at the bottom
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 12
                color: Theme.buttonSecondary

                Text {
                    text: "Done"
                    color: Theme.buttonSecondaryText
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: contactDetailsPopup.close()
                }
            }

            Item { Layout.fillHeight: true } // spacer
        }
    }
}

