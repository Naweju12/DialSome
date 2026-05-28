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
    // --- CALL STATUS HEADER (Always visible but styled dynamically) ---
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 40
        Layout.preferredHeight: 110
        spacing: 8

        Text {
            text: myBackend.activePeers.length > 1 ? "Conference Call" : "Voice Call"
            color: Theme.textSecondary
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }

        Text {
            text: callPage.formatDuration(callPage.callDuration)
            color: Theme.success
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: 32
            font.weight: Font.Bold
            visible: myBackend.callConnected
        }

        Text {
            text: myBackend.message
            color: Theme.textSecondary
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.preferredWidth: parent.width * 0.8
        }
    }

    // --- DYNAMIC CONTENT AREA ---
    StackLayout {
        id: callContentStack
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 20
        currentIndex: myBackend.activePeers.length > 1 ? 1 : 0

        // Slide 0: Single Call UI (Original large avatar and name)
        ColumnLayout {
            spacing: 20
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item { Layout.fillHeight: true } // spacer

            // Avatar
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 120
                height: 120
                radius: 60
                color: "transparent"
                border.color: Theme.accent
                border.width: 2

                Rectangle {
                    anchors.centerIn: parent
                    width: 110
                    height: 110
                    radius: 55
                    color: Theme.surfaceVariant

                    Image {
                        source: "../icons/user.png"
                        sourceSize.width: 110
                        sourceSize.height: 110
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                SequentialAnimation on border.width {
                    running: myBackend.callConnected && myBackend.activePeers.length <= 1
                    loops: Animation.Infinite
                    NumberAnimation { to: 4; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.5; duration: 1000; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: myBackend.callerName
                color: Theme.textPrimary
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 26
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.preferredWidth: parent.width * 0.9
            }

            Item { Layout.fillHeight: true } // spacer
        }

        // Slide 1: Conference Call UI (List of participants)
        ColumnLayout {
            spacing: 12
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                text: "PARTICIPANTS (" + (myBackend.activePeers.length + 1) + ")"
                color: Theme.textSecondary
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.letterSpacing: 1
                Layout.leftMargin: 8
            }

            ListView {
                id: participantsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: myBackend.activePeers
                spacing: 8
                clip: true

                delegate: Rectangle {
                    width: participantsList.width
                    height: 64
                    radius: 16
                    color: Theme.card
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        // Small Avatar / Icon
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 10
                            color: Theme.surfaceVariant

                            Text {
                                text: modelData.charAt(0).toUpperCase()
                                color: Theme.textPrimary
                                font.weight: Font.DemiBold
                                font.pixelSize: 16
                                anchors.centerIn: parent
                                visible: modelData.length > 0
                            }
                        }

                        // Participant Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData
                                color: Theme.textPrimary
                                font.weight: Font.DemiBold
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                spacing: 6
                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: Theme.success
                                }
                                Text {
                                    text: "Connected"
                                    color: Theme.textSecondary
                                    font.pixelSize: 11
                                }
                            }
                        }

                        // Disconnect Button
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 10
                            color: disconnectArea.pressed ? Qt.darker(Theme.danger, 1.2) : Theme.danger
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                source: "../icons/dial.png"
                                sourceSize.width: 18
                                sourceSize.height: 18
                                anchors.centerIn: parent
                                rotation: 135 // red decline phone icon angle
                                fillMode: Image.PreserveAspectFit
                            }

                            MouseArea {
                                id: disconnectArea
                                anchors.fill: parent
                                onClicked: myBackend.disconnectPeer(modelData)
                                onPressed: parent.scale = 0.9
                                onReleased: parent.scale = 1.0
                            }

                            Behavior on scale {
                                NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }
            }
        }
    }

    // --- ACTION BUTTONS ---
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 25
        spacing: 20

        // Speaker Toggle
        ColumnLayout {
            spacing: 6
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                id: speakerBtn
                color: myBackend.speakerOn ? Theme.actionButtonActive : Theme.actionButton
                height: 60
                width: 60
                radius: 18
                Layout.alignment: Qt.AlignHCenter

                Image {
                    source: myBackend.speakerOn ? "../icons/volume_on.png" : "../icons/volume_off.png"
                    sourceSize.width: 26
                    sourceSize.height: 26
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: myBackend.setSpeakerOn(!myBackend.speakerOn)
                    onPressed: parent.scale = 0.9
                    onReleased: parent.scale = 1.0
                }

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
                Behavior on scale {
                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                }
            }

            Text {
                text: "Speaker"
                color: Theme.textSecondary
                font.pixelSize: 11
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // Mic Mute
        ColumnLayout {
            spacing: 6
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                id: micMuteBtn
                color: myBackend.micMuted ? Theme.actionButtonActive : Theme.actionButton
                height: 60
                width: 60
                radius: 18
                Layout.alignment: Qt.AlignHCenter

                Image {
                    source: myBackend.micMuted ? "../icons/mic_off.png" : "../icons/mic_on.png"
                    sourceSize.width: 26
                    sourceSize.height: 26
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: myBackend.setMicMuted(!myBackend.micMuted)
                    onPressed: parent.scale = 0.9
                    onReleased: parent.scale = 1.0
                }

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
                Behavior on scale {
                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                }
            }

            Text {
                text: "Mute"
                color: Theme.textSecondary
                font.pixelSize: 11
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // Add Call
        ColumnLayout {
            spacing: 6
            Layout.alignment: Qt.AlignHCenter
            visible: myBackend.activePeers.length < 4

            Rectangle {
                id: addCallBtn
                color: Theme.actionButton
                height: 60
                width: 60
                radius: 18
                Layout.alignment: Qt.AlignHCenter

                Image {
                    source: "../icons/add.png"
                    sourceSize.width: 26
                    sourceSize.height: 26
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mainStack.push(selectContactPageComponent)
                    onPressed: parent.scale = 0.9
                    onReleased: parent.scale = 1.0
                }

                Behavior on scale {
                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                }
            }

            Text {
                text: "Add"
                color: Theme.textSecondary
                font.pixelSize: 11
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // End Call
        ColumnLayout {
            spacing: 6
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                id: endCallBtn
                color: endCallArea.pressed ? Qt.darker(Theme.danger, 1.2) : Theme.danger
                height: 60
                width: 60
                radius: 18
                Layout.alignment: Qt.AlignHCenter

                Image {
                    source: "../icons/dial.png"
                    sourceSize.width: 28
                    sourceSize.height: 28
                    anchors.centerIn: parent
                    rotation: 135
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    id: endCallArea
                    anchors.fill: parent
                    onClicked: myBackend.endCall()
                    onPressed: parent.scale = 0.9
                    onReleased: parent.scale = 1.0
                }

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
                Behavior on scale {
                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                }
            }

            Text {
                text: "End"
                color: Theme.danger
                font.pixelSize: 11
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // --- MERGE CALL BUTTON ---
    Rectangle {
        id: mergeCallBtn
        visible: myBackend.hasHeldPeers
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 30
        height: 48
        width: 180
        radius: 24
        color: mergeArea.pressed ? Qt.darker(Theme.success, 1.2) : Theme.success

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
                color: "#FFFFFF"
                font.weight: Font.DemiBold
                font.pixelSize: 14
            }
        }

        MouseArea {
            id: mergeArea
            anchors.fill: parent
            onClicked: {
                myBackend.mergeCalls();
                myUtils.showToast("Calls merged successfully!");
            }
            onPressed: parent.scale = 0.95
            onReleased: parent.scale = 1.0
        }

        Behavior on color {
            ColorAnimation { duration: 100 }
        }
        Behavior on scale {
            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }
    }
}
