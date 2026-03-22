#include "backend.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QCoreApplication>
#include <QDebug>
#include <QPermissions>
#include <QStandardPaths>
#include <QDir>
#include <QFile>

static Backend* s_instance = nullptr;

Backend::Backend(QObject *parent) : QObject(parent) {
    s_instance = this;
    this->m_storage = new SecureStorage(parent);
    this->m_google = new Google(this, this->m_storage);
    this->m_settings = new Settings(this);

    QString historyJson = m_storage->get("call_history");
    if (!historyJson.isEmpty()) {
        QJsonDocument doc = QJsonDocument::fromJson(historyJson.toUtf8());
        m_recentCalls = doc.toVariant().toList();
    }

    connect(this, &Backend::settingsLoaded, this, [this]() {
        QString hostUrl = this->m_settings->getHttpProtocol() + "://" + this->m_settings->getHost();
        QUrl url(hostUrl);
        QNetworkRequest request(url);

        qDebug() << "Attempting to connect to the server..." + hostUrl;

        QNetworkReply *reply = m_networkManager.head(request);
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                qDebug() << "Server Connected";
                this->m_serverConnected = true;
                emit this->serverConnectionChanged();

                if (!this->m_storage->getRefreshToken().isEmpty()) {
                    this->m_api->fetch_contacts(this->m_jwtAccessToken);
                }
            } else {
                qDebug() << "Server Disconnected";
            }
            reply->deleteLater();
        });

    });

    connect(this->m_google, &Google::dataCollectionFinished, this, [this](const QString &email, const QString &displayName, const QString &idToken, const QString &userID) {
        QString hostUrl = this->m_settings->getHttpProtocol() + "://" + this->m_settings->getHost() + "/users/register";
        QUrl url(hostUrl);
        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("Authorization", "Bearer " + idToken.toUtf8());

        QNetworkReply *reply = m_networkManager.post(request, QByteArray());
        connect(reply, &QNetworkReply::finished, this, [this, reply, idToken]() {
            int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            qDebug() << "HTTP Status Code:" << statusCode;

            if (statusCode == 201 || statusCode == 409) {
                QByteArray responseData = reply->readAll();

                QJsonParseError parseError;
                QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData, &parseError);

                if (parseError.error == QJsonParseError::NoError && jsonDoc.isObject()) {
                    QJsonObject jsonObj = jsonDoc.object();

                    if (jsonObj.contains("status")) {
                        bool statusValue = jsonObj.value("status").toBool();
                        qDebug() << "Server Status:" << statusValue;
                        emit this->registerFinished(idToken);
                    }
                } else {
                    qDebug() << "JSON Parse Error:" << parseError.errorString();
                    emit this->loginError("Network Error");
                }
            } else {
                qDebug() << "Network Error:" << reply->errorString();
                emit this->loginError("Network Error");
            }
            reply->deleteLater();
        });
    });

    connect(this, &Backend::registerFinished, this, [this](const QString &idToken) {
        QString hostUrl = this->m_settings->getHttpProtocol() + "://" + this->m_settings->getHost() + "/users/login";
        QUrl url(hostUrl);
        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("Authorization", "Bearer " + idToken.toUtf8());

        QNetworkReply *reply = m_networkManager.post(request, QByteArray());
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            qDebug() << "HTTP Status Code:" << statusCode;

            if (reply->error() == QNetworkReply::NoError && statusCode == 200) {
                QByteArray responseData = reply->readAll();

                QJsonParseError parseError;
                QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData, &parseError);

                if (parseError.error == QJsonParseError::NoError && jsonDoc.isObject()) {
                    QJsonObject jsonObj = jsonDoc.object();

                    if (jsonObj.contains("status")) {
                        bool statusValue = jsonObj.value("status").toBool();
                        qDebug() << "Server Status:" << statusValue;
                        
                        if (statusValue && jsonObj.contains("data")) {
                            QJsonObject dataJson = jsonObj.value("data").toObject();
                            if (dataJson.contains("id") && dataJson.contains("email") && dataJson.contains("firstname") && dataJson.contains("lastname")) {
                                QString id = dataJson.value("id").toString();
                                QString email = dataJson.value("email").toString();
                                QString firstname = dataJson.value("firstname").toString();

                                if (dataJson.contains("jwt")) {
                                    QJsonObject jwtJson = dataJson.value("jwt").toObject();
                                    if (jwtJson.contains("refresh_token") && jwtJson.contains("access_token")) {
                                        QString refresh_token = jwtJson.value("refresh_token").toString();
                                        this->m_jwtAccessToken = jwtJson.value("access_token").toString();
                                        emit this->loginFinished(email, firstname, id, refresh_token);
                                    }
                                }
                            }
                        }
                    }
                } else {
                    qDebug() << "JSON Parse Error:" << parseError.errorString();
                    emit this->loginError("Network Error");
                }
            } else {
                qDebug() << "Network Error:" << reply->errorString();
                emit this->loginError("Network Error");
            }
            reply->deleteLater();
        });
    });

    connect(this, &Backend::loginFinished, this, [this](const QString &email, const QString &displayName, const QString &userID, const QString &refresh_token) {
        this->m_storage->saveRefreshToken(refresh_token);
        this->m_storage->save("id", userID); 

        QString cachedToken = this->m_storage->get("fcm_token");
        if (!cachedToken.isEmpty()) {
            this->m_fcm->updateTokenOnBackend(cachedToken);
        }
        
        this->requestNotificationPermission();
        
        // REQUEST BATTERY EXEMPTION
        #ifdef Q_OS_ANDROID
        QJniObject context = QNativeInterface::QAndroidApplication::context();
        if (context.isValid()) {
            QJniObject::callStaticMethod<void>(
                "com/github/biltudas1/dialsome/AndroidUtils",
                "requestIgnoreBatteryOptimizations",
                "(Landroid/content/Context;)V",
                context.object()
            );
        }
        #endif
    });

    connect(m_api, &APIService::contactsFetched, this, [this](QVariantList contacts) {
        m_contacts = contacts;
        emit contactsChanged();
    });

    connect(m_api, &APIService::contactsFetchError, this, [this](QString error) {
        qDebug() << "Failed to load contacts:" << error;
    });

    connect(&m_webSocket, &QWebSocket::connected, this, &Backend::onConnected);
    connect(&m_webSocket, &QWebSocket::textMessageReceived, this, &Backend::onTextMessageReceived);

    #ifdef Q_OS_ANDROID
        QJniObject context = QNativeInterface::QAndroidApplication::context();
        QJniObject roomIdJni = QJniObject::callStaticMethod<jstring>(
            "com/github/biltudas1/dialsome/AndroidUtils",
            "getIncomingRoomId",
            "(Landroid/content/Context;)Ljava/lang/String;",
            context.object()
        );

        QJniObject roomNameJni = QJniObject::callStaticMethod<jstring>(
            "com/github/biltudas1/dialsome/AndroidUtils",
            "getIncomingRoomName",
            "(Landroid/content/Context;)Ljava/lang/String;",
            context.object()
        );

        QJniObject emailJni = QJniObject::callStaticMethod<jstring>(
            "com/github/biltudas1/dialsome/AndroidUtils",
            "getIncomingCallerEmail",
            "(Landroid/content/Context;)Ljava/lang/String;",
            context.object()
        );

        QString roomId = roomIdJni.toString();
        QString roomName = roomNameJni.toString();
        QString email = emailJni.toString();

        if (!roomId.isEmpty()) {
            qDebug() << "App was woken up for a call! Room:" << roomId;
            saveToHistory(email, roomName, true);
            // Optionally prompt the user, or immediately join:
            joinCall(roomId, email, roomName);
        }
    #endif
}

extern "C" {
JNIEXPORT void JNICALL Java_com_github_biltudas1_dialsome_WebRTCManager_onLocalIceCandidate(
    JNIEnv* env, jobject, jstring sdp, jstring mid, jint index) {
    if (!s_instance) return;
    QString sdpStr = QJniObject(sdp).toString();
    QString midStr = QJniObject(mid).toString();
    QMetaObject::invokeMethod(s_instance, [=]() {
        QJsonObject json;
        json["type"] = "candidate";
        json["sdp"] = sdpStr;
        json["sdpMid"] = midStr;
        json["sdpMLineIndex"] = (int)index;
        s_instance->handleLocalIce(json);
    }, Qt::QueuedConnection);
}

JNIEXPORT void JNICALL Java_com_github_biltudas1_dialsome_WebRTCManager_onLocalSdp(
    JNIEnv* env, jobject, jstring sdp, jstring type) {
    if (!s_instance) return;
    QString sdpStr = QJniObject(sdp).toString();
    QString typeStr = QJniObject(type).toString();
    QMetaObject::invokeMethod(s_instance, [=]() {
        QJsonObject json;
        json["type"] = typeStr;
        json["sdp"] = sdpStr;
        s_instance->handleLocalSdp(json);
    }, Qt::QueuedConnection);
}

JNIEXPORT void JNICALL Java_com_github_biltudas1_dialsome_WebRTCManager_onCallEstablished(JNIEnv*, jobject) {
    if (!s_instance) return;
    QMetaObject::invokeMethod(s_instance, [=]() {
        s_instance->setMessage("Call Connected! Audio is live.");
    }, Qt::QueuedConnection);
}

JNIEXPORT void JNICALL Java_com_github_biltudas1_dialsome_WebRTCManager_onCallDisconnected(JNIEnv*, jobject) {
    if (!s_instance) return;
    QMetaObject::invokeMethod(s_instance, [=]() {
        qDebug() << "Call disconnected via WebRTC ICE state change";
        s_instance->endCall();
    }, Qt::QueuedConnection);
}

JNIEXPORT void JNICALL Java_com_github_biltudas1_dialsome_MainActivity_acceptCallNative(
    JNIEnv* env, jobject, jstring roomId, jstring email, jstring name) {
    
    if (!s_instance) return;

    QString rId = QJniObject(roomId).toString();
    QString mail = QJniObject(email).toString();
    QString n = QJniObject(name).toString();

    QMetaObject::invokeMethod(s_instance, [=]() {
        qDebug() << "User pressed ACCEPT on notification. Joining call now...";
        s_instance->joinCall(rId, mail, n);
    }, Qt::QueuedConnection);
}
}

void Backend::startCall(const QString &email) {
    if (!this->m_callerEmail.isEmpty() || this->m_webrtc.isValid()) {
        qDebug() << "Call already in progress, ignoring startCall.";
        return;
    }

    #ifdef Q_OS_ANDROID
        QMicrophonePermission micPermission;
        qApp->requestPermission(micPermission, [this, email](const QPermission &permission) {
            if (permission.status() != Qt::PermissionStatus::Granted) {
                setMessage("Microphone permission denied!");
                return;
            }

            this->m_isCaller = true;
            setMessage("Connecting to the server...");
            connect(this->m_api, &APIService::roomFetched, this, [this, email](QString roomId, QString roomName) {
                this->setMessage("Connecting to the room: " + roomId);
                QString wsURL = this->m_settings->getWSProtocol() + "://" + this->m_settings->getHost() + "/ws/" + roomId;
                m_webSocket.open(QUrl(wsURL));
                
                this->m_callerEmail = email;
                this->m_callerName = roomName;

                this->saveToHistory(email, roomName, false);
                emit this->startingCall();
                emit this->callerInfoChanged();

                QJniObject context = QNativeInterface::QAndroidApplication::context();
                m_webrtc = QJniObject("com/github/biltudas1/dialsome/WebRTCManager");

                if (m_webrtc.isValid()) {
                    m_webrtc.callMethod<void>("init", "(Landroid/content/Context;)V", context.object());
                    // Pre-initialize PC so tracks are ready
                    m_webrtc.callMethod<void>("createPeerConnection");
                }
            }, Qt::SingleShotConnection);

            this->m_api->get_room(email, this->m_jwtAccessToken);
        });
    #endif
}

void Backend::joinCall(const QString &roomId, const QString &email, const QString &roomName) {
    if (!this->m_callerEmail.isEmpty() || this->m_webrtc.isValid()) {
        qDebug() << "Call already in progress, ignoring joinCall.";
        return;
    }

    #ifdef Q_OS_ANDROID
        QMicrophonePermission micPermission;
        qApp->requestPermission(micPermission, [this, roomId, email, roomName](const QPermission &permission) {
            if (permission.status() != Qt::PermissionStatus::Granted) {
                setMessage("Microphone permission denied!");
                return;
            }

            this->m_isCaller = false;

            // Skip the POST request! We already have the roomId.
            this->setMessage("Joining room: " + roomId);
            
            QString wsURL = this->m_settings->getWSProtocol() + "://" + this->m_settings->getHost() + "/ws/" + roomId;
            m_webSocket.open(QUrl(wsURL));
            
            // Initialize WebRTC exactly like the caller
            QJniObject context = QNativeInterface::QAndroidApplication::context();
            m_webrtc = QJniObject("com/github/biltudas1/dialsome/WebRTCManager");
            
            if (m_webrtc.isValid()) {
                emit this->startingCall();
                this->m_callerEmail = email;
                this->m_callerName = roomName;
                emit this->callerInfoChanged();
                m_webrtc.callMethod<void>("init", "(Landroid/content/Context;)V", context.object());
                m_webrtc.callMethod<void>("createPeerConnection");
            }
        });
    #endif
}

void Backend::onConnected() {
    setMessage("Signaling connected. Waiting for peer...");
    QJsonObject joinJson;
    joinJson["type"] = "join";
    m_webSocket.sendTextMessage(QJsonDocument(joinJson).toJson(QJsonDocument::Compact));
}

void Backend::handleLocalIce(const QJsonObject &json) {
    if (m_webSocket.isValid())
        m_webSocket.sendTextMessage(QJsonDocument(json).toJson(QJsonDocument::Compact));
}

void Backend::handleLocalSdp(const QJsonObject &json) {
    if (m_webSocket.isValid())
        m_webSocket.sendTextMessage(QJsonDocument(json).toJson(QJsonDocument::Compact));
}

void Backend::onTextMessageReceived(const QString &message) {
    QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8());
    QJsonObject json = doc.object();
    QString type = json["type"].toString();

    if (type == "join") {
        if (this->m_isCaller) {
            setMessage("Peer joined. Sending Offer...");
            m_webrtc.callMethod<void>("createOffer");
        } else {
            setMessage("Joined room. Waiting for caller...");
        }
    } else if (type == "offer" || type == "answer") {
        m_webrtc.callMethod<void>("handleRemoteSdp",
                                  "(Ljava/lang/String;Ljava/lang/String;)V",
                                  QJniObject::fromString(json["sdp"].toString()).object(),
                                  QJniObject::fromString(type).object());
    } else if (type == "candidate") {
        m_webrtc.callMethod<void>("addRemoteIceCandidate",
                                  "(Ljava/lang/String;Ljava/lang/String;I)V",
                                  QJniObject::fromString(json["sdp"].toString()).object(),
                                  QJniObject::fromString(json["sdpMid"].toString()).object(),
                                  json["sdpMLineIndex"].toInt());
    }
}

QString Backend::message() const { return m_message; }
void Backend::setMessage(const QString &msg) { m_message = msg; emit messageChanged(); }

void Backend::Startup() {
    if (this->m_api != nullptr) {
        qDebug() << "Backend already initialized, ignoring Startup.";
        return;
    }

    qDebug() << "App started: Loading Settings...";

    if (this->m_settings.isNull()) {
        qDebug() << "Settings failed to load";
        return;
    }

    this->m_api = new APIService(this->m_settings, this->m_storage, this);
    this->m_fcm = new FCMManager(this->m_storage, this);

    // Updates the Refresh and Access Token
    connect(this->m_api, &APIService::tokenRefreshed, this, [this](QString accessToken, QString refreshToken) {
        this->m_storage->saveRefreshToken(refreshToken);
        this->m_jwtAccessToken = accessToken;
    });

    // Session Expired
    connect(this->m_api, &APIService::invalidSession, this, [this]() {
        emit this->invalidSession("Session Expired! Please login again");
    });
    
    // Update FCM Token
    connect(this->m_fcm, &FCMManager::fcmTokenReceived, this, [this](const QString &token) {
        this->m_api->update_fcm(token, this->m_jwtAccessToken);
    });

    connect(this->m_fcm, &FCMManager::callSignalReceived, this, [this](const QString &roomId, const QString &email, const QString &roomName) {
        qDebug() << "Starting the call";
        this->setMessage("Incoming call from " + email);
        this->saveToHistory(email, roomName, true);
        // this->joinCall(roomId, email, roomName);
    });

    connect(this->m_fcm, &FCMManager::callEndingSignal, this, [this]() {
        this->endCall();
    });

    emit this->settingsLoaded();
}

bool Backend::serverConnected() const { return m_serverConnected; }

void Backend::requestNotificationPermission() {
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    
    if (activity.isValid()) {
        QJniEnvironment env;
        
        jstring permString = env->NewStringUTF("android.permission.POST_NOTIFICATIONS");
        jclass stringClass = env->FindClass("java/lang/String");
        jobjectArray permArray = env->NewObjectArray(1, stringClass, permString);

        activity.callMethod<void>("requestPermissions", "([Ljava/lang/String;I)V", permArray, 123);
        
        // Clean up local refs
        env->DeleteLocalRef(permArray);
        env->DeleteLocalRef(permString);
    }
}

void Backend::endCall() {
    if (this->m_webrtc.isValid()) {
        this->m_webrtc.callMethod<void>("close", "()V");
        this->m_webrtc = QJniObject(); // Clear the object
    }

    if (m_webSocket.isValid()) {
        m_webSocket.close();
    }

    this->m_callerEmail = ""; 
    this->m_callerName = "";
    this->m_isCaller = false;

    qDebug() << "Call Ended";
    emit this->callEnded();
}

QString Backend::callerEmail() const {
    return this->m_callerEmail;
}

QString Backend::callerName() const {
    return this->m_callerName;
}

QString Backend::serverUrl() const { 
    return m_settings->get("Server/host").toString(); 
}
bool Backend::useHttps() const {
    return m_settings->get("Protocol/https").toBool(); 
}
bool Backend::useWss() const {
    return m_settings->get("Protocol/wss").toBool();
}

void Backend::setServerUrl(const QString &url) {
    if (this->serverUrl() != url) {
        m_settings->save("Server/host", url);
        emit this->serverUrlChanged();
    }
}

void Backend::setUseHttps(bool value) {
    if (this->useHttps() != value) {
        m_settings->save("Protocol/https", value);
        emit this->useHttpsChanged();
    }
}

void Backend::setUseWss(bool value) {
    if (this->useWss() != value) {
        m_settings->save("Protocol/wss", value);
        emit this->useWssChanged();
    }
}

void Backend::saveToHistory(const QString &email, const QString &name, bool isIncoming) {
    QVariantMap log;
    log["email"] = email;
    log["name"] = name;
    log["isIncoming"] = isIncoming;
    log["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);

    // Add to the beginning of the list
    m_recentCalls.prepend(log);

    // Keep only the last 50 calls
    while (m_recentCalls.size() > 50) m_recentCalls.removeLast();

    // Save back to local storage
    QJsonDocument doc = QJsonDocument::fromVariant(m_recentCalls);
    m_storage->save("call_history", doc.toJson(QJsonDocument::Compact));
    
    emit recentCallsChanged();
}

QVariantList Backend::recentCalls() const {
    return m_recentCalls;
}

QVariantList Backend::contacts() const {
    return m_contacts;
}
