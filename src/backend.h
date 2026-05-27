#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include <QDateTime>
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
    Q_PROPERTY(QString serverUrl READ serverUrl WRITE setServerUrl NOTIFY serverUrlChanged)
    Q_PROPERTY(bool useHttps READ useHttps WRITE setUseHttps NOTIFY useHttpsChanged)
    Q_PROPERTY(bool useWss READ useWss WRITE setUseWss NOTIFY useWssChanged)
    Q_PROPERTY(QVariantList recentCalls READ recentCalls NOTIFY recentCallsChanged)
    Q_PROPERTY(QVariantList contacts READ contacts NOTIFY contactsChanged)
    Q_PROPERTY(bool speakerOn READ speakerOn WRITE setSpeakerOn NOTIFY speakerOnChanged)
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
    QString serverUrl() const;
    bool useHttps() const;
    bool useWss() const;
    void setServerUrl(const QString &url);
    void setUseHttps(bool value);
    void setUseWss(bool value);
    QVariantList recentCalls() const;
    void saveToHistory(const QString &email, const QString &name, bool isIncoming);
    QVariantList contacts() const;
    Q_INVOKABLE void addContact(const QString &email);
    Q_INVOKABLE void acceptCall();
    bool speakerOn() const;
    Q_INVOKABLE void setSpeakerOn(bool on);
    Q_INVOKABLE bool canUseFullScreenIntent();
    Q_INVOKABLE void requestFullScreenIntentPermission();
    QString myEmail() const { return m_myEmail; }
    void addActivePeer(const QString &email);
    void removeActivePeer(const QString &email);

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
    void serverUrlChanged();
    void useHttpsChanged();
    void useWssChanged();
    void recentCallsChanged();
    void contactsChanged();
    void incomingCall();
    void speakerOnChanged();

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
    QString m_incomingRoomId = "";
    QVariantList m_recentCalls;
    QVariantList m_contacts;
    bool m_speakerOn = false;
    QString m_myEmail = "";
    QStringList m_activePeers;
};

#endif
