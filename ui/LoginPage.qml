import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Rectangle {
    id: loginPage
    anchors.fill: parent
    color: Theme.background

    property bool isLoggingIn: false
    property string statusText: ""

    Behavior on color {
        ColorAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

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

        // --- APP BRANDING ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            // Icon container with glow
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 120
                height: 120
                radius: 60
                color: Theme.surface
                border.color: Theme.border
                border.width: 1.5

                // Ambient glow
                Rectangle {
                    anchors.centerIn: parent
                    width: 136
                    height: 136
                    radius: 68
                    color: Theme.accent
                    opacity: 0.14
                    z: -1
                }

                Image {
                    source: "qrc:/qt/qml/DialSome/icons/logo.png"
                    width: 64
                    height: 64
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit

                    // Pulse animation when logging in
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
                color: Theme.textPrimary
                font.pixelSize: 28
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Simple • Secure • Instant"
                color: Theme.textSecondary
                font.pixelSize: 14
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // --- LOGIN / LOADING AREA ---
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
                    Material.background: Theme.accent
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

            // Loading indicator (Fades in when logging in)
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
                    Material.accent: Theme.accent
                }

                Text {
                    id: statusLabel
                    text: loginPage.statusText
                    color: Theme.accent
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter

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
