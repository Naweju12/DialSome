import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import DialSome
import "ui"

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 360
    height: 640
    title: "DialSome"
    color: Theme.background

    leftPadding: 15
    rightPadding: 15

    Behavior on color {
        ColorAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    Backend {
        id: myBackend

        Component.onCompleted: {
            myBackend.Startup();
        }
    }

    Utils {
        id: myUtils
    }

    StackView {
        id: mainStack
        anchors.fill: parent
        initialItem: myBackend.google.isLoggedIn() ? mainDashboardComponent : loginPageComponent
    }

    Component {
        id: loginPageComponent
        LoginPage {}
    }

    Component {
        id: mainDashboardComponent
        MainPage {}
    }

    Component {
        id: callingPageComponent
        CallingPage {}
    }

    Component {
        id: incomingCallPageComponent
        IncomingCallPage {}
    }

    Component {
        id: settingsPageComponent
        SettingsPage {}
    }

    Component {
        id: selectContactPageComponent
        SelectContactPage {}
    }

    Connections {
        target: myBackend
        function onLoginFinished(email, name, userid, refresh_token) {
            myUtils.showToast("Welcome " + name)
            mainStack.replace(mainDashboardComponent)
        }
        function onLoginError(error) {
            myUtils.showToast(error)
        }
        function onInvalidSession(error) {
            myUtils.showToast(error)
            mainStack.replace(loginPageComponent)
        }
        function onStartingCall() {
            mainStack.push(callingPageComponent)
        }
        function onIncomingCall() {
            mainStack.push(incomingCallPageComponent)
        }
        function onCallEnded() {
            mainStack.pop()
        }
    }
}
