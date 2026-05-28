import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: callingPageRoot
    color: Theme.background

    Behavior on color {
        ColorAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

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

    ColumnLayout {
        id: callPage
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 0

        // --- DYNAMIC CONTENT AREA ---
        StackLayout {
            id: callContentStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: myBackend.conferenceParticipants.length > 1 ? 1 : 0

            // Slide 0: Single Call UI (Avatar -> Name -> Duration)
            ColumnLayout {
                spacing: 8
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Avatar centered at top
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 48
                    width: 140
                    height: 140
                    radius: 70
                    color: "transparent"
                    border.color: Theme.accent
                    border.width: 2

                    Rectangle {
                        anchors.centerIn: parent
                        width: 128
                        height: 128
                        radius: 64
                        color: Theme.surfaceVariant

                        Image {
                            source: "../icons/user.png"
                            sourceSize.width: 128
                            sourceSize.height: 128
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

                // Name (centered)
                Text {
                    text: myBackend.callerName
                    color: Theme.textPrimary
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 32
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                // Email (centered, soft text)
                Text {
                    text: myBackend.callerEmail
                    color: Theme.textSecondary
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 15
                    elide: Text.ElideRight
                }

                // Call Duration or Connection message (centered)
                Text {
                    text: myBackend.callConnected ? callingPageRoot.formatDuration(callingPageRoot.callDuration) : myBackend.message
                    color: myBackend.callConnected ? Theme.success : Theme.textSecondary
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: myBackend.callConnected ? 32 : 16
                    font.weight: myBackend.callConnected ? Font.Bold : Font.Medium
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            // Slide 1: Conference Call UI (List of participants)
            ColumnLayout {
                spacing: 12
                Layout.fillWidth: true
                Layout.fillHeight: true

                // --- CONFERENCE STATUS HEADER ---
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    Layout.preferredHeight: 70
                    spacing: 8

                    Text {
                        text: "Conference Call"
                        color: Theme.textSecondary
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                    }

                    Text {
                        text: callingPageRoot.formatDuration(callingPageRoot.callDuration)
                        color: Theme.success
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 32
                        font.weight: Font.Bold
                        visible: myBackend.callConnected
                    }
                }

                Text {
                    text: "PARTICIPANTS (" + myBackend.conferenceParticipants.length + ")"
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
                model: myBackend.conferenceParticipants
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
                                text: modelData.name ? modelData.name.charAt(0).toUpperCase() : ""
                                color: Theme.textPrimary
                                font.weight: Font.DemiBold
                                font.pixelSize: 16
                                anchors.centerIn: parent
                                visible: modelData.name && modelData.name.length > 0
                            }
                        }

                        // Participant Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.name
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
                                    color: {
                                        if (modelData.status === "Connected") return Theme.success;
                                        if (modelData.status === "Ringing") return Theme.accent;
                                        return Theme.textSecondary; // "On Hold"
                                    }
                                }
                                Text {
                                    text: modelData.status + " • " + modelData.email
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
                                onClicked: myBackend.disconnectPeer(modelData.email)
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


}
}


