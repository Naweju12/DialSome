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

    // --- CALLER INFO ---
    Rectangle {
        id: titleSection
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        Layout.topMargin: 50
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            // Avatar with subtle ring
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 88
                height: 88
                radius: 44
                color: "transparent"
                border.color: Theme.accent
                border.width: 2

                Rectangle {
                    anchors.centerIn: parent
                    width: 80
                    height: 80
                    radius: 40
                    color: Theme.surfaceVariant

                    Image {
                        source: "../icons/user.png"
                        sourceSize.width: 80
                        sourceSize.height: 80
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                // Pulsing ring when connected
                SequentialAnimation on border.width {
                    running: myBackend.callConnected
                    loops: Animation.Infinite
                    NumberAnimation { to: 3; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.5; duration: 1000; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: myBackend.callerName
                color: Theme.textPrimary
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: myBackend.callerName.indexOf(",") !== -1 ? 18 : 28
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.preferredWidth: parent.width * 0.9
            }

            Text {
                text: myBackend.message
                color: Theme.textSecondary
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 15
            }

            Text {
                text: callPage.formatDuration(callPage.callDuration)
                color: Theme.success
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 18
                font.weight: Font.DemiBold
                visible: myBackend.callConnected
            }
        }
    }

    // Push to top
    Item {
        Layout.fillHeight: true
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
