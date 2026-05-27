import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Rectangle {
    id: loginPage
    anchors.fill: parent
    color: "#0B0F19" // Modern premium dark blue/grey background

    property bool isLoggingIn: false
    property string statusText: ""

    Connections {
        target: myBackend
        function onLoginFinished(email, name, userid, refresh_token) {
            loginPage.isLoggingIn = false
        }
        function onLoginError(error) {
            loginPage.isLoggingIn = false
            myUtils.showToast("Login failed: " + error)
        }
    }

    Connections {
        target: myBackend.google
        function onDataCollectionFinished(email, displayName, idToken, userID) {
            loginPage.statusText = "Connecting to DialSome..."
        }
        function onDataCollectionError(error) {
            loginPage.isLoggingIn = false
            myUtils.showToast("Google sign-in cancelled")
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.85, 320)
        spacing: 35

        // App Branding Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 16

            // Beautiful circular container for the icon with integrated glow
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 120
                height: 120
                radius: 60
                color: "#131A26" // Slightly lighter dark blue for depth
                border.color: "#1E293B" // Subtle modern border
                border.width: 1.5

                // Subtle ambient glow centered behind the container
                Rectangle {
                    anchors.centerIn: parent
                    width: 136
                    height: 136
                    radius: 68
                    color: "#3B82F6" // Brand blue glow
                    opacity: 0.14
                    z: -1
                }

                Image {
                    source: "qrc:/qt/qml/DialSome/icons/logo.png"
                    width: 64
                    height: 64
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                    
                    // Pulse opacity animation when logging in
                    NumberAnimation on opacity {
                        running: loginPage.isLoggingIn
                        from: 1.0; to: 0.4
                        duration: 1000
                        loops: Animation.Infinite
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Text {
                text: "DialSome"
                color: "#FFFFFF"
                font.pixelSize: 28
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Simple • Secure • Instant"
                color: "#94A3B8"
                font.pixelSize: 14
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // Interactive / Loading Area
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            Layout.alignment: Qt.AlignHCenter

            // Google Login Button (Fades out when logging in)
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: 15
                opacity: loginPage.isLoggingIn ? 0.0 : 1.0
                visible: opacity > 0.0
                
                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }

                Button {
                    text: "Sign in with Google"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    Material.background: "#2563EB"
                    Material.foreground: "#FFFFFF"
                    font.pixelSize: 15
                    font.bold: true

                    onClicked: {
                        loginPage.isLoggingIn = true
                        loginPage.statusText = "Authenticating with Google..."
                        myBackend.google.loginWithGoogle("87640868239-dje4suitg3fi100c8hirlunckcji4g40.apps.googleusercontent.com")
                    }
                }
            }

            // Premium Busy Indicator & Status (Fades in when logging in)
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: 20
                opacity: loginPage.isLoggingIn ? 1.0 : 0.0
                visible: opacity > 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }

                BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: loginPage.isLoggingIn
                    Material.accent: "#3B82F6"
                }

                Text {
                    id: statusLabel
                    text: loginPage.statusText
                    color: "#3B82F6"
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                    
                    // Simple smooth opacity transition when text changes
                    Behavior on text {
                        SequentialAnimation {
                            NumberAnimation { target: statusLabel; property: "opacity"; to: 0; duration: 80 }
                            PropertyAction { target: statusLabel; property: "text" }
                            NumberAnimation { target: statusLabel; property: "opacity"; to: 1; duration: 120 }
                        }
                    }
                }
            }
        }
    }
}
