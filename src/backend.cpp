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
    this->m_myEmail = this->m_storage->get("email");

    QString historyJson = m_storage->get("call_history");
    if (!historyJson.isEmpty()) {
        QJsonDocument doc = QJsonDocument::fromJson(historyJson.toUtf8());
        m_recentCalls = doc.toVariant().toList();
    }

    QString blockedJson = m_storage->get("blocked_users");
    if (!blockedJson.isEmpty()) {
        QJsonDocument doc = QJsonDocument::fromJson(blockedJson.toUtf8());
        QVariantList varList = doc.toVariant().toList();
        for (const QVariant &var : varList) {
            m_blockedUsers.append(var.toString());
        }
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
        QString loginUrlStr = this->m_settings->getHttpProtocol() + "://" + this->m_settings->getHost() + "/users/login";
        QUrl loginUrl(loginUrlStr);
        QNetworkRequest loginRequest(loginUrl);
        loginRequest.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        loginRequest.setRawHeader("Authorization", "Bearer " + idToken.toUtf8());

        qDebug() << "Fast-Path: Attempting direct login first...";
        QNetworkReply *loginReply = m_networkManager.post(loginRequest, QByteArray());
        connect(loginReply, &QNetworkReply::finished, this, [this, loginReply, idToken]() {
            int statusCode = loginReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            qDebug() << "Fast-Path Login status code:" << statusCode;

            if (loginReply->error() == QNetworkReply::NoError && statusCode == 200) {
                QByteArray responseData = loginReply->readAll();
                QJsonParseError parseError;
                QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData, &parseError);

                if (parseError.error == QJsonParseError::NoError && jsonDoc.isObject()) {
                    QJsonObject jsonObj = jsonDoc.object();
                    if (jsonObj.contains("status") && jsonObj.value("status").toBool() && jsonObj.contains("data")) {
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
                                    qDebug() << "Fast-Path: Direct login successful!";
                                    emit this->loginFinished(email, firstname, id, refresh_token);
                                    loginReply->deleteLater();
                                    return;
                                }
                            }
                        }
                    }
                }
                qDebug() << "Fast-Path: Parsing failed despite 200 OK.";
                emit this->loginError("Network Error");
            } else if (statusCode == 404) {
                // User is not registered! Fall back to registration.
                qDebug() << "Fast-Path: User not found (404). Falling back to register...";
                
                QString registerUrlStr = this->m_settings->getHttpProtocol() + "://" + this->m_settings->getHost() + "/users/register";
                QUrl registerUrl(registerUrlStr);
                QNetworkRequest registerRequest(registerUrl);
                registerRequest.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
                registerRequest.setRawHeader("Authorization", "Bearer " + idToken.toUtf8());

                QNetworkReply *registerReply = m_networkManager.post(registerRequest, QByteArray());
                connect(registerReply, &QNetworkReply::finished, this, [this, registerReply, idToken]() {
                    int regStatusCode = registerReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
                    qDebug() << "Fallback Register status code:" << regStatusCode;

                    if (regStatusCode == 201 || regStatusCode == 409) {
                        // Registration success, now login to get tokens
                        qDebug() << "Fallback Register successful. Logging in now...";
                        
                        QString finalLoginUrlStr = this->m_settings->getHttpProtocol() + "://" + this->m_settings->getHost() + "/users/login";
                        QUrl finalLoginUrl(finalLoginUrlStr);
                        QNetworkRequest finalLoginRequest(finalLoginUrl);
                        finalLoginRequest.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
                        finalLoginRequest.setRawHeader("Authorization", "Bearer " + idToken.toUtf8());

                        QNetworkReply *finalLoginReply = m_networkManager.post(finalLoginRequest, QByteArray());
                        connect(finalLoginReply, &QNetworkReply::finished, this, [this, finalLoginReply]() {
                            int finalStatusCode = finalLoginReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
                            qDebug() << "Final Login status code:" << finalStatusCode;

                            if (finalLoginReply->error() == QNetworkReply::NoError && finalStatusCode == 200) {
                                QByteArray finalData = finalLoginReply->readAll();
                                QJsonParseError finalParseError;
                                QJsonDocument finalDoc = QJsonDocument::fromJson(finalData, &finalParseError);

                                if (finalParseError.error == QJsonParseError::NoError && finalDoc.isObject()) {
                                    QJsonObject finalObj = finalDoc.object();
                                    if (finalObj.contains("status") && finalObj.value("status").toBool() && finalObj.contains("data")) {
                                        QJsonObject dataJson = finalObj.value("data").toObject();
                                        if (dataJson.contains("id") && dataJson.contains("email") && dataJson.contains("firstname") && dataJson.contains("lastname")) {
                                            QString id = dataJson.value("id").toString();
                                            QString email = dataJson.value("email").toString();
                                            QString firstname = dataJson.value("firstname").toString();

                                            if (dataJson.contains("jwt")) {
                                                QJsonObject jwtJson = dataJson.value("jwt").toObject();
                                                if (jwtJson.contains("refresh_token") && jwtJson.contains("access_token")) {
                                                    QString refresh_token = jwtJson.value("refresh_token").toString();
                                                    this->m_jwtAccessToken = jwtJson.value("access_token").toString();
                                                    qDebug() << "Fallback Login successful!";
                                                    emit this->loginFinished(email, firstname, id, refresh_token);
                                                    finalLoginReply->deleteLater();
                                                    return;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            qDebug() << "Fallback Login failed.";
                            emit this->loginError("Network Error");
                            finalLoginReply->deleteLater();
                        });
                    } else {
                        qDebug() << "Fallback Register failed:" << registerReply->errorString();
                        emit this->loginError("Network Error");
                    }
                    registerReply->deleteLater();
                });
            } else {
                qDebug() << "Fast-Path Login failed with error:" << loginReply->errorString();
                emit this->loginError("Network Error");
            }
            loginReply->deleteLater();
        });
    });

    connect(this, &Backend::loginFinished, this, [this](const QString &email, const QString &displayName, const QString &userID, const QString &refresh_token) {
        this->m_myEmail = email;
        this->m_storage->save("email", email);
        this->m_storage->saveRefreshToken(refresh_token);
        this->m_storage->save("id", userID); 

        // Fetch contacts immediately upon login
        if (this->m_api) {
            this->m_api->fetch_contacts(this->m_jwtAccessToken);
        }

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

    connect(&m_webSocket, &QWebSocket::connected, this, &Backend::onConnected);
    connect(&m_webSocket, &QWebSocket::textMessageReceived, this, &Backend::onTextMessageReceived);
}

extern "C" {
JNIEXPORT void JNICALL Java_com_github_biltudas1_dialsome_WebRTCManager_onLocalIceCandidate(
    JNIEnv* env, jobject, jstring peerEmail, jstring sdp, jstring mid, jint index) {
    if (!s_instance) return;
    QString email = QJniObject(peerEmail).toString();
    QString sdpStr = QJniObject(sdp).toString();
    QString midStr = QJniObject(mid).toString();
    QMetaObject::invokeMethod(s_instance, [=]() {
        QJsonObject json;
        json["type"] = "candidate";
        json["sender"] = s_instance->myEmail();
        json["target"] = email;
        json["sdp"] = sdpStr;
        json["sdpMid"] = midStr;
        json["sdpMLineIndex"] = (int)index;
        s_instance->handleLocalIce(json);
    }, Qt::QueuedConnection);
}

JNIEXPORT void JNICALL Java_com_github_biltudas1_dialsome_WebRTCManager_onLocalSdp(
    JNIEnv* env, jobject, jstring peerEmail, jstring sdp, jstring type) {
    if (!s_instance) return;
    QString email = QJniObject(peerEmail).toString();
    QString sdpStr = QJniObject(sdp).toString();
    QString typeStr = QJniObject(type).toString();
    QMetaObject::invokeMethod(s_instance, [=]() {
        QJsonObject json;
        json["type"] = typeStr;
        json["sender"] = s_instance->myEmail();
        json["target"] = email;
        json["sdp"] = sdpStr;
        s_instance->handleLocalSdp(json);
    }, Qt::QueuedConnection);
}

JNIEXPORT void JNICALL Java_com_github_biltudas1_dialsome_WebRTCManager_onCallEstablished(JNIEnv* env, jobject, jstring peerEmail) {
    if (!s_instance) return;
    QString email = QJniObject(peerEmail).toString();
    QMetaObject::invokeMethod(s_instance, [=]() {
        s_instance->addActivePeer(email);
    }, Qt::QueuedConnection);
}

JNIEXPORT void JNICALL Java_com_github_biltudas1_dialsome_WebRTCManager_onCallDisconnected(JNIEnv* env, jobject, jstring peerEmail) {
    if (!s_instance) return;
    QString email = QJniObject(peerEmail).toString();
    QMetaObject::invokeMethod(s_instance, [=]() {
        s_instance->removeActivePeer(email);
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

JNIEXPORT void JNICALL Java_com_github_biltudas1_dialsome_MainActivity_showIncomingCallNative(
    JNIEnv* env, jobject, jstring roomId, jstring email, jstring name) {
    
    if (!s_instance) return;

    QString rId = QJniObject(roomId).toString();
    QString mail = QJniObject(email).toString();
    QString n = QJniObject(name).toString();

    QMetaObject::invokeMethod(s_instance, [=]() {
        qDebug() << "Woken up by Full Screen Intent. Showing UI...";
        FCMManager::instance()->processIncomingSignal(rId, mail, n);
    }, Qt::QueuedConnection);
}
}

void Backend::startCall(const QString &email) {
    if (this->m_webrtc.isValid()) {
        qDebug() << "Call already in progress, ignoring startCall.";
        return;
    }

    this->m_isCaller = true;
    this->m_callerEmail = email;
    this->m_callerName = callerNameForEmail(email);
    this->setMessage("Connecting to the server...");
    emit this->startingCall();
    emit this->callerInfoChanged();

    #ifdef Q_OS_ANDROID
        QMicrophonePermission micPermission;
        qApp->requestPermission(micPermission, [this, email](const QPermission &permission) {
            if (permission.status() != Qt::PermissionStatus::Granted) {
                setMessage("Microphone permission denied!");
                endCall();
                return;
            }

            connect(this->m_api, &APIService::roomFetched, this, [this, email](QString roomId, QString roomName) {
                this->m_currentRoomId = roomId;
                this->setMessage("Connecting to the room: " + roomId);
                QString wsURL = this->m_settings->getWSProtocol() + "://" + this->m_settings->getHost() + "/ws/" + roomId;
                m_webSocket.open(QUrl(wsURL));
                
                this->m_callerEmail = email;
                this->m_callerName = roomName;

                this->saveToHistory(email, roomName, false);
                emit this->callerInfoChanged();

                QJniObject context = QNativeInterface::QAndroidApplication::context();
                m_webrtc = QJniObject("com/github/biltudas1/dialsome/WebRTCManager");

                if (m_webrtc.isValid()) {
                    m_webrtc.callMethod<void>("init", "(Landroid/content/Context;)V", context.object());
                }
            }, Qt::SingleShotConnection);

            this->m_api->get_room(email, this->m_jwtAccessToken);
        });
    #else
        this->saveToHistory(email, this->m_callerName, false);
    #endif
}

void Backend::joinCall(const QString &roomId, const QString &email, const QString &roomName) {
    if (this->m_webrtc.isValid()) {
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
            this->m_currentRoomId = roomId;

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
            }
        });
    #endif
}

void Backend::onConnected() {
    setMessage("Signaling connected. Waiting for peer...");
    QJsonObject joinJson;
    joinJson["type"] = "join";
    joinJson["sender"] = this->m_myEmail;
    joinJson["email"] = this->m_myEmail;
    joinJson["name"] = "Me";
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
    QString sender = json["sender"].toString();
    QString target = json["target"].toString();

    // 1. If targeted message and not for us, ignore it
    if (json.contains("target") && !target.isEmpty() && target != this->m_myEmail) {
        return;
    }

    if (type == "join") {
        if (sender == this->m_myEmail) return; // ignore our own broadcast
        
        qDebug() << "Peer joined:" << sender;
        
        // Dynamic Peer Connection creation
        if (m_webrtc.isValid()) {
            m_webrtc.callMethod<void>("createPeerConnection", "(Ljava/lang/String;)V", QJniObject::fromString(sender).object());
        }
        
        // Lexicographical sorting rule to determine who creates the offer.
        // The lexicographically smaller email address initiates the offer.
        if (this->m_myEmail < sender) {
            setMessage("Sending offer to " + sender);
            if (m_webrtc.isValid()) {
                m_webrtc.callMethod<void>("createOffer", "(Ljava/lang/String;)V", QJniObject::fromString(sender).object());
            }
        } else {
            // Send welcome back so they can create a PeerConnection for us
            QJsonObject welcomeJson;
            welcomeJson["type"] = "welcome";
            welcomeJson["sender"] = this->m_myEmail;
            welcomeJson["target"] = sender;
            m_webSocket.sendTextMessage(QJsonDocument(welcomeJson).toJson(QJsonDocument::Compact));
            setMessage("Welcomed peer: " + sender);
        }
    }
    else if (type == "welcome") {
        if (sender == this->m_myEmail) return; // ignore our own welcome
        
        qDebug() << "Received welcome from:" << sender;
        
        // Create Peer Connection for the welcoming peer
        if (m_webrtc.isValid()) {
            m_webrtc.callMethod<void>("createPeerConnection", "(Ljava/lang/String;)V", QJniObject::fromString(sender).object());
        }
        
        if (this->m_myEmail < sender) {
            setMessage("Sending offer to " + sender);
            if (m_webrtc.isValid()) {
                m_webrtc.callMethod<void>("createOffer", "(Ljava/lang/String;)V", QJniObject::fromString(sender).object());
            }
        }
    }
    else if (type == "offer" || type == "answer") {
        if (m_webrtc.isValid()) {
            // Dynamically create PeerConnection on demand if it doesn't exist yet
            if (type == "offer") {
                m_webrtc.callMethod<void>("createPeerConnection", "(Ljava/lang/String;)V", QJniObject::fromString(sender).object());
            }
            
            m_webrtc.callMethod<void>("handleRemoteSdp",
                                      "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
                                      QJniObject::fromString(sender).object(),
                                      QJniObject::fromString(json["sdp"].toString()).object(),
                                      QJniObject::fromString(type).object());
        }
    }
    else if (type == "candidate") {
        if (m_webrtc.isValid()) {
            m_webrtc.callMethod<void>("addRemoteIceCandidate",
                                      "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)V",
                                      QJniObject::fromString(sender).object(),
                                      QJniObject::fromString(json["sdp"].toString()).object(),
                                      QJniObject::fromString(json["sdpMid"].toString()).object(),
                                      json["sdpMLineIndex"].toInt());
        }
    }
    else if (type == "leave") {
        if (sender == this->m_myEmail) return;
        qDebug() << "Peer left:" << sender;
        removeActivePeer(sender);
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

    // Updates the UI of Contacts
    connect(m_api, &APIService::contactsFetched, this, [this](QVariantList contacts) {
        m_contacts = contacts;
        emit this->contactsChanged();
    });

    connect(m_api, &APIService::contactsFetchError, this, [this](QString error) {
        qDebug() << "Failed to load contacts:" << error;
    });

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
        if (isUserBlocked(email)) {
            qDebug() << "Blocking incoming call from:" << email;
            if (this->m_api != nullptr) {
                this->m_api->end_call(email, this->m_jwtAccessToken);
            }
            return;
        }

        qDebug() << "Incoming call screen triggered";
        this->setMessage("Incoming call from " + email);
        this->saveToHistory(email, roomName, true);
        
        // Store data and trigger the UI
        this->m_incomingRoomId = roomId;
        this->m_callerEmail = email;
        this->m_callerName = roomName;
        emit this->callerInfoChanged();
        emit this->incomingCall();
    });

    connect(this->m_fcm, &FCMManager::callEndingSignal, this, [this]() {
        this->endCall();
    });

    emit this->settingsLoaded();

    #ifdef Q_OS_ANDROID
    qDebug() << "Notifying Android that Qt UI is fully loaded and ready.";
    QJniObject::callStaticMethod<void>(
        "com/github/biltudas1/dialsome/MainActivity",
        "notifyQtReady"
    );
    #endif
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
    bool shouldSendEndCallApi = false;
    QString peersToNotify = "";

    if (this->m_api != nullptr) {
        if (this->m_isCaller) {
            // Case 1: Initiator ends the call. Notify all participants (active, held, and initial callee)
            QStringList list;
            if (!this->m_callerEmail.isEmpty()) {
                for (const QString &email : this->m_callerEmail.split(",")) {
                    QString trimmed = email.trimmed();
                    if (!trimmed.isEmpty() && !list.contains(trimmed)) {
                        list.append(trimmed);
                    }
                }
            }
            for (const QString &peer : this->m_activePeers) {
                if (!peer.isEmpty() && !list.contains(peer)) {
                    list.append(peer);
                }
            }
            for (const QString &peer : this->m_heldPeers) {
                if (!peer.isEmpty() && !list.contains(peer)) {
                    list.append(peer);
                }
            }
            if (!list.isEmpty()) {
                peersToNotify = list.join(",");
                shouldSendEndCallApi = true;
            }
        } else if (!this->m_incomingRoomId.isEmpty() && !this->m_callerEmail.isEmpty()) {
            // Case 2: Callee rejects an incoming call before answering. Notify the caller to stop ringing.
            peersToNotify = this->m_callerEmail;
            shouldSendEndCallApi = true;
        }
    }

    if (shouldSendEndCallApi && !peersToNotify.isEmpty()) {
        qDebug() << "Notifying server to end call for:" << peersToNotify;
        this->m_api->end_call(peersToNotify, this->m_jwtAccessToken);
    }

    // Case 3: Active callee leaves. Notify active peers over websocket first
    if (m_webSocket.isValid()) {
        QJsonObject leaveJson;
        leaveJson["type"] = "leave";
        leaveJson["sender"] = this->m_myEmail;
        m_webSocket.sendTextMessage(QJsonDocument(leaveJson).toJson(QJsonDocument::Compact));
        m_webSocket.close();
    }

    if (this->m_webrtc.isValid()) {
        this->m_webrtc.callMethod<void>("close", "()V");
        this->m_webrtc = QJniObject(); // Clear the object
    }

    // Clear the Android notification in case they hit "Reject" on the QML UI
    #ifdef Q_OS_ANDROID
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (context.isValid()) {
        QJniObject::callStaticMethod<void>(
            "com/github/biltudas1/dialsome/MainActivity",
            "clearCallNotification",
            "(Landroid/content/Context;)V",
            context.object()
        );
    }
    #endif

    this->m_activePeers.clear();
    this->m_heldPeers.clear();
    this->m_dialingPeers.clear();
    this->m_micMuted = false;
    this->m_callerEmail = ""; 
    this->m_callerName = "";
    this->m_isCaller = false;
    this->m_currentRoomId = "";
    this->m_incomingRoomId = "";

    qDebug() << "Call Ended";
    emit this->callEnded();
    emit this->callerInfoChanged();
    emit this->heldPeersChanged();
    emit this->micMutedChanged();
    emit this->callConnectedChanged();
}

QString Backend::callerEmail() const {
    if (!m_activePeers.isEmpty()) {
        return m_activePeers.join(", ");
    }
    return this->m_callerEmail;
}

QString Backend::callerNameForEmail(const QString &email) const {
    for (const QVariant &c : m_contacts) {
        QVariantMap map = c.toMap();
        if (map["email"].toString().trimmed().compare(email.trimmed(), Qt::CaseInsensitive) == 0) {
            return map["name"].toString();
        }
    }
    if (email.contains("@")) {
        return email.split("@").first();
    }
    return email;
}

QVariantList Backend::conferenceParticipants() const {
    QVariantList list;
    QStringList addedEmails;

    // 1. Check active peers
    for (const QString &email : m_activePeers) {
        if (addedEmails.contains(email)) continue;

        QVariantMap map;
        map["email"] = email;
        map["name"] = callerNameForEmail(email);
        if (m_heldPeers.contains(email)) {
            map["status"] = "On Hold";
        } else {
            map["status"] = "Connected";
        }
        list.append(map);
        addedEmails.append(email);
    }

    // 2. Check held peers
    for (const QString &email : m_heldPeers) {
        if (addedEmails.contains(email)) continue;

        QVariantMap map;
        map["email"] = email;
        map["name"] = callerNameForEmail(email);
        map["status"] = "On Hold";
        list.append(map);
        addedEmails.append(email);
    }

    // 3. Check dialing peers
    for (const QString &email : m_dialingPeers) {
        if (addedEmails.contains(email)) continue;

        QVariantMap map;
        map["email"] = email;
        map["name"] = callerNameForEmail(email);
        map["status"] = "Ringing";
        list.append(map);
        addedEmails.append(email);
    }

    return list;
}

QString Backend::callerName() const {
    if (!m_activePeers.isEmpty()) {
        if (m_activePeers.size() == 1) {
            return callerNameForEmail(m_activePeers.first());
        }
        return m_activePeers.join(", ");
    }
    return this->m_callerName;
}

void Backend::addActivePeer(const QString &email) {
    if (m_dialingPeers.contains(email)) {
        m_dialingPeers.removeAll(email);
    }
    if (!m_activePeers.contains(email)) {
        m_activePeers.append(email);
        emit callerInfoChanged();
        emit callConnectedChanged();
    }
    setMessage("Call Connected! Active peers: " + m_activePeers.join(", "));

    // Auto-merge calls if there is a held peer (i.e. we are in a conference dial situation)
    if (!m_heldPeers.isEmpty()) {
        qDebug() << "Auto-merging new participant connection:" << email;
        mergeCalls();
    }
}

void Backend::removeActivePeer(const QString &email) {
    if (m_dialingPeers.contains(email)) {
        m_dialingPeers.removeAll(email);
        emit callerInfoChanged();
    }
    if (m_activePeers.contains(email)) {
        m_activePeers.removeAll(email);
        emit callerInfoChanged();
        emit callConnectedChanged();
    }
    if (m_heldPeers.contains(email)) {
        m_heldPeers.removeAll(email);
        emit heldPeersChanged();
    }
    #ifdef Q_OS_ANDROID
    if (m_webrtc.isValid()) {
        m_webrtc.callMethod<void>("closePeer", "(Ljava/lang/String;)V", QJniObject::fromString(email).object());
    }
    #endif
    if (m_activePeers.isEmpty() && m_dialingPeers.isEmpty()) {
        setMessage("All peers disconnected.");
        endCall();
    } else {
        setMessage("Peer disconnected. Active peers: " + m_activePeers.join(", "));
    }
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

void Backend::addContact(const QString &email) {
    if (email.isEmpty()) return;

    qDebug() << "Requesting to add contact:" << email;

    this->m_api->add_contact(email, this->m_jwtAccessToken);
}

void Backend::acceptCall() {
    if (!m_incomingRoomId.isEmpty()) {
        // Join the WebRTC room now that the user has accepted
        joinCall(m_incomingRoomId, m_callerEmail, m_callerName);
        m_incomingRoomId.clear();

        // Clear the Android notification to stop the ringtone
        #ifdef Q_OS_ANDROID
        QJniObject context = QNativeInterface::QAndroidApplication::context();
        if (context.isValid()) {
            QJniObject::callStaticMethod<void>(
                "com/github/biltudas1/dialsome/MainActivity",
                "clearCallNotification",
                "(Landroid/content/Context;)V",
                context.object()
            );
        }
        #endif
    }
}

bool Backend::speakerOn() const {
    return m_speakerOn;
}

void Backend::setSpeakerOn(bool on) {
    if (m_speakerOn == on) return;
    m_speakerOn = on;
    emit speakerOnChanged();

    #ifdef Q_OS_ANDROID
    if (m_webrtc.isValid()) {
        m_webrtc.callMethod<void>("setSpeaker", "(Z)V", on);
    }
    #endif
}

bool Backend::canUseFullScreenIntent() {
    #ifdef Q_OS_ANDROID
        // Call the static Java method canUseFullScreenIntent in AndroidUtils
        jboolean result = QJniObject::callStaticMethod<jboolean>(
            "com/github/biltudas1/dialsome/AndroidUtils",
            "canUseFullScreenIntent",
            "(Landroid/content/Context;)Z",
            QNativeInterface::QAndroidApplication::context()
        );
        return result;
    #else
        return true; // Not Android, permission doesn't apply
    #endif
}

void Backend::requestFullScreenIntentPermission() {
    #ifdef Q_OS_ANDROID
        // Call the static Java method requestFullScreenIntentPermission in AndroidUtils
        QJniObject::callStaticMethod<void>(
            "com/github/biltudas1/dialsome/AndroidUtils",
            "requestFullScreenIntentPermission",
            "(Landroid/content/Context;)V",
            QNativeInterface::QAndroidApplication::context()
        );
    #endif
}

void Backend::inviteToCall(const QString &email) {
    if (email.isEmpty() || m_currentRoomId.isEmpty()) {
        qDebug() << "Cannot invite: email is empty or no active room ID.";
        return;
    }
    qDebug() << "Inviting peer:" << email << "to active room:" << m_currentRoomId;
    this->m_api->get_room(email, this->m_jwtAccessToken, this->m_currentRoomId);
}

void Backend::setPeerMuted(const QString &email, bool mute) {
    #ifdef Q_OS_ANDROID
    if (m_webrtc.isValid()) {
        m_webrtc.callMethod<void>("setPeerMuted", "(Ljava/lang/String;Z)V",
                                  QJniObject::fromString(email).object(), mute);
    }
    #endif
}

void Backend::dialNewParticipant(const QString &email) {
    if (email.isEmpty() || m_currentRoomId.isEmpty()) {
        qDebug() << "Cannot dial new participant: email is empty or no active room ID.";
        return;
    }

    qDebug() << "Dialing new participant:" << email << "Muting current participants...";

    if (!m_dialingPeers.contains(email)) {
        m_dialingPeers.append(email);
    }

    // 1. Mute all currently active peers (place them on hold)
    for (const QString &peer : m_activePeers) {
        if (!m_heldPeers.contains(peer)) {
            m_heldPeers.append(peer);
            setPeerMuted(peer, true);
        }
    }
    emit heldPeersChanged();
    emit callerInfoChanged();

    // 2. Set message to reflect dialing status
    setMessage("Calling " + email + " (existing participants on hold)");

    // 3. Dial/invite the new participant to the same room ID
    this->m_api->get_room(email, this->m_jwtAccessToken, this->m_currentRoomId);
}

void Backend::mergeCalls() {
    qDebug() << "Merging calls. Unmuting all held participants...";

    // 1. Unmute all held peers
    for (const QString &peer : m_heldPeers) {
        setPeerMuted(peer, false);
    }

    // 2. Clear held peers
    m_heldPeers.clear();
    emit heldPeersChanged();
    emit callerInfoChanged();

    // 3. Update message
    setMessage("Call Connected! Active peers: " + m_activePeers.join(", "));
}

void Backend::setMicMuted(bool muted) {
    if (m_micMuted == muted) return;
    m_micMuted = muted;
    emit micMutedChanged();

    #ifdef Q_OS_ANDROID
    if (m_webrtc.isValid()) {
        m_webrtc.callMethod<void>("setMicrophoneMuted", "(Z)V", muted);
    }
    #endif
}

QString Backend::appVersion() const {
#ifdef Q_OS_ANDROID
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (context.isValid()) {
        QJniObject packageName = context.callObjectMethod("getPackageName", "()Ljava/lang/String;");
        QJniObject packageManager = context.callObjectMethod("getPackageManager", "()Landroid/content/pm/PackageManager;");
        if (packageManager.isValid() && packageName.isValid()) {
            // Retrieve PackageInfo
            QJniObject packageInfo = packageManager.callObjectMethod(
                "getPackageInfo",
                "(Ljava/lang/String;I)Landroid/content/pm/PackageInfo;",
                packageName.object(),
                0
            );
            if (packageInfo.isValid()) {
                QJniObject versionName = packageInfo.getObjectField("versionName", "Ljava/lang/String;");
                if (versionName.isValid()) {
                    return versionName.toString();
                }
            }
        }
    }
#endif
    return "1.0";
}

void Backend::disconnectPeer(const QString &email) {
    if (email.isEmpty()) return;
    qDebug() << "Disconnecting specific peer:" << email;
    if (this->m_api != nullptr) {
        this->m_api->end_call(email, this->m_jwtAccessToken);
    }
    removeActivePeer(email);
}

void Backend::blockUser(const QString &email) {
    if (email.isEmpty()) return;
    QString trimmed = email.trimmed();
    if (!m_blockedUsers.contains(trimmed)) {
        m_blockedUsers.append(trimmed);
        
        QJsonArray arr;
        for (const QString &blocked : m_blockedUsers) {
            arr.append(blocked);
        }
        QJsonDocument doc(arr);
        m_storage->save("blocked_users", doc.toJson(QJsonDocument::Compact));
        
        emit blockedUsersChanged();
        qDebug() << "User blocked successfully:" << trimmed;
    }
}

void Backend::unblockUser(const QString &email) {
    QString trimmed = email.trimmed();
    if (m_blockedUsers.contains(trimmed)) {
        m_blockedUsers.removeAll(trimmed);
        
        QJsonArray arr;
        for (const QString &blocked : m_blockedUsers) {
            arr.append(blocked);
        }
        QJsonDocument doc(arr);
        m_storage->save("blocked_users", doc.toJson(QJsonDocument::Compact));
        
        emit blockedUsersChanged();
        qDebug() << "User unblocked successfully:" << trimmed;
    }
}

bool Backend::isUserBlocked(const QString &email) const {
    QString trimmed = email.trimmed();
    return m_blockedUsers.contains(trimmed);
}






