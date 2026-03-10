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
    color: "#000000"

    leftPadding: 15
    rightPadding: 15

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
        function onCallEnded() {
            mainStack.pop()
        }
    }
}
