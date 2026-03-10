#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include <QString>
#include <QJniObject>
#include <QJsonObject>
#include <QtWebSockets/QWebSocket>
#include <QtQmlIntegration/qqmlintegration.h>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSettings>
#include <QScopedPointer>
#include "lib/google.h"
#include "lib/settings.h"
#include "lib/apiservice.h"
#include "fcmmanager.h"

class Backend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString message READ message NOTIFY messageChanged)
    Q_PROPERTY(bool serverConnected READ serverConnected NOTIFY serverConnectionChanged)
    Q_PROPERTY(Google* google READ google CONSTANT)
    Q_PROPERTY(QString callerEmail READ callerEmail NOTIFY callerInfoChanged)
    Q_PROPERTY(QString callerName READ callerName NOTIFY callerInfoChanged)

public:
    explicit Backend(QObject *parent = nullptr);
    QString message() const;
    void setMessage(const QString &msg);
    Q_INVOKABLE void startCall(const QString &email);
    Q_INVOKABLE void joinCall(const QString &roomId, const QString &email, const QString &roomName);
    void handleLocalIce(const QJsonObject &json);
    void handleLocalSdp(const QJsonObject &json);
    Q_INVOKABLE void Startup();
    bool serverConnected() const;
    Google* google() const { return m_google; }
    void requestNotificationPermission();
    Q_INVOKABLE void endCall();
    QString callerName() const;
    QString callerEmail() const;

signals:
    void messageChanged();
    void settingsLoaded();
    void serverConnectionChanged();
    void registerFinished(const QString &idToken);
    void loginFinished(const QString &email, const QString &displayName, const QString &userID, const QString &refresh_token);
    void loginError(const QString &error);
    void invalidSession(const QString &error);
    void startingCall();
    void callEnded();
    void callerInfoChanged();

private slots:
    void onTextMessageReceived(const QString &message);
    void onConnected();

private:
    QString m_message = "Ready";
    QNetworkAccessManager m_networkManager;
    QWebSocket m_webSocket;
    QJniObject m_webrtc;
    bool m_serverConnected = false;
    QString m_jwtAccessToken = "";
    QPointer<Google> m_google;
    QPointer<SecureStorage> m_storage;
    QPointer<FCMManager> m_fcm;
    QPointer<Settings> m_settings;
    QPointer<APIService> m_api;
    bool m_isCaller = false;
    QString m_callerEmail = ""; // Email of the other party
    QString m_callerName = "User"; // Name of the other party
};

#endif
