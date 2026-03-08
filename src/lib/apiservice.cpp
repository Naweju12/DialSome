#include "apiservice.h"

APIService::APIService(QPointer<Settings> settings, QPointer<SecureStorage> storage, QObject *parent) : QObject(parent) {
    this->m_settings = settings;
    this->m_storage = storage;
}

void APIService::update_fcm(QString fcm_token, QString accessToken) {
    bool triedRefreshing = false;
    connect(this, &APIService::tokenRefreshed, this, [this, triedRefreshing, fcm_token](QString accessToken, QString refreshToken) {
        QString host = this->m_settings->getHttpProtocol() + "://" + this->m_settings->getHost() + API::FCM::updateDevice;
        QUrl hostUrl(host);
        QNetworkRequest request(hostUrl);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("Authorization", "Bearer " + accessToken.toUtf8());

        QJsonObject json;
        json["fcm_token"] = fcm_token;
    
        QNetworkReply *reply = this->m_networkManager.post(request, QJsonDocument(json).toJson(QJsonDocument::Compact));
        connect(reply, &QNetworkReply::finished, this, [this, reply, host, triedRefreshing]() mutable {
            int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            if (reply->error() == QNetworkReply::NoError) {
                qDebug() << "FCM Token Updated";
            } else if (statusCode == 401) {
                if (!triedRefreshing) {
                    qDebug() << "Unauthorized! Refreshing Access Token...";
                    triedRefreshing = true;
                    this->refreshToken();
                } else {
                    emit this->invalidSession(); 
                }
            }
            reply->deleteLater();
        });
    });
    connect(this, &APIService::tokenRefreshError, this, [this](QString error) {
        qDebug() << "FCM Token Update Failed:" << error;
        emit this->invalidSession();
    });
    emit this->tokenRefreshed(accessToken, this->m_storage->getRefreshToken());
}

void APIService::get_room(QString email, QString accessToken) {
    bool triedRefreshing = false;
    connect(this, &APIService::tokenRefreshed, this, [this, triedRefreshing, email](QString accessToken, QString refreshToken) {
        QString hostUrl = this->m_settings->getHttpProtocol() + "://" + this->m_settings->getHost() + API::Voice::call;
        QUrl url(hostUrl);
        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("Authorization", "Bearer " + accessToken.toUtf8());

        QJsonObject json;
        json["email"] = email;

        QNetworkReply *reply = m_networkManager.post(request, QJsonDocument(json).toJson(QJsonDocument::Compact));
        connect(reply, &QNetworkReply::finished, this, [reply, this, triedRefreshing]() mutable {
            int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            if (statusCode == 401) {
                if (!triedRefreshing) {
                    qDebug() << "Unauthorized! Refreshing Access Token...";
                    triedRefreshing = true;
                    this->refreshToken();
                } else {
                    emit this->invalidSession(); 
                }
                reply->deleteLater();
                return;
            }

            if (reply->error() != QNetworkReply::NoError) {
                qDebug() << "Failed to retrieve RoomID:" << reply->errorString();
                emit this->roomFetchError("Failed to connect to the server");
                reply->deleteLater();
                return;
            }

            QByteArray responseData = reply->readAll();

            QJsonParseError parseError;
            QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData, &parseError);

            if (parseError.error != QJsonParseError::NoError || !jsonDoc.isObject()) {
                qDebug() << "JSON Parse Error:" << parseError.errorString();
                emit this->roomFetchError("Failed to connect to the server");
                reply->deleteLater();
                return;
            }

            QJsonObject jsonObj = jsonDoc.object();

            if (!jsonObj.contains("data")) {
                qDebug() << "JSON doesn't contains `data` key";
                emit this->roomFetchError("Failed to connect to the server");
                reply->deleteLater();
                return;
            }
            QJsonObject dataJson = jsonObj.value("data").toObject();

            if (dataJson.contains("room_id")) {
                QString roomId = dataJson.value("room_id").toString();
                emit this->roomFetched(roomId);
            } else {
                qDebug() << "No `room_id` key found";
                emit this->roomFetchError("Failed to connect to the server");
            }
        
            reply->deleteLater();
        });
    });
    connect(this, &APIService::tokenRefreshError, this, [this](QString error) {
        qDebug() << "Fetching Room Details Failed:" << error;
        emit this->invalidSession();
    });
    emit this->tokenRefreshed(accessToken, this->m_storage->getRefreshToken());
}

void APIService::refreshToken() {
    QString host = this->m_settings->getHttpProtocol() + "://" + this->m_settings->getHost() + API::Auth::refresh;
    QUrl hostUrl(host);
    QNetworkRequest request(hostUrl);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["refresh_token"] = this->m_storage->getRefreshToken();

    QNetworkReply *reply = this->m_networkManager.post(request, QJsonDocument(json).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() != QNetworkReply::NoError) {
            emit this->tokenRefreshError("failed to refresh token");
            reply->deleteLater();
            return;
        }

        QByteArray responseData = reply->readAll();

        QJsonParseError parseError;
        QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData, &parseError);

        if (parseError.error != QJsonParseError::NoError || !jsonDoc.isObject()) {
            emit this->tokenRefreshError("response is not a valid json");
            reply->deleteLater();
            return;
        }
        QJsonObject jsonObj = jsonDoc.object();

        if (!jsonObj.contains("data")) {
            emit this->tokenRefreshError("response doesn't contains `data` field");
            reply->deleteLater();
            return;
        }

        QJsonObject dataJson = jsonObj.value("data").toObject();

        if (dataJson.contains("access_token") && dataJson.contains("refresh_token")) {
            QString access = dataJson.value("access_token").toString();
            QString refresh = dataJson.value("refresh_token").toString();

            emit this->tokenRefreshed(access, refresh);
        } else {
            emit this->tokenRefreshError("data object doesn't contains `access_token` and `refresh_token`");
        }
        reply->deleteLater();
    });
}

void APIService::end_call(QString email, QString accessToken) {
    bool triedRefreshing = false;
    connect(this, &APIService::tokenRefreshed, this, [this, triedRefreshing, email](QString accessToken, QString refreshToken) {
        QString hostUrl = this->m_settings->getHttpProtocol() + "://" + this->m_settings->getHost() + API::Voice::endCall;
        QUrl url(hostUrl);
        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("Authorization", "Bearer " + accessToken.toUtf8());

        QJsonObject json;
        json["email"] = email;

        QNetworkReply *reply = m_networkManager.sendCustomRequest(request, "DELETE", QJsonDocument(json).toJson(QJsonDocument::Compact));
        connect(reply, &QNetworkReply::finished, this, [reply, this, triedRefreshing]() mutable {
            int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            if (statusCode == 401) {
                if (!triedRefreshing) {
                    qDebug() << "Unauthorized! Refreshing Access Token...";
                    triedRefreshing = true;
                    this->refreshToken();
                } else {
                    emit this->invalidSession(); 
                }
                reply->deleteLater();
                return;
            }

            if (reply->error() != QNetworkReply::NoError) {
                qDebug() << "Failed to process ending call request:" << reply->errorString();
                emit this->roomFetchError("Failed to connect to the server");
                reply->deleteLater();
                return;
            }

            QByteArray responseData = reply->readAll();

            QJsonParseError parseError;
            QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData, &parseError);

            if (parseError.error != QJsonParseError::NoError || !jsonDoc.isObject()) {
                qDebug() << "JSON Parse Error:" << parseError.errorString();
                emit this->roomFetchError("Failed to connect to the server");
                reply->deleteLater();
                return;
            }

            QJsonObject jsonObj = jsonDoc.object();
            if (!jsonObj.contains("status")) {
                qDebug() << "JSON doesn't contains `status` key";
                emit this->roomFetchError("Failed to connect to the server");
                reply->deleteLater();
                return;
            }

            if (jsonObj.value("status").toBool()) {
                emit this->endCallSuccess();
            } else {
                emit this->endCallFailed();
            }
            reply->deleteLater();
        });
    });
    connect(this, &APIService::tokenRefreshError, this, [this](QString error) {
        qDebug() << "Sending call termination request Failed:" << error;
        emit this->invalidSession();
    });
    emit this->tokenRefreshed(accessToken, this->m_storage->getRefreshToken());
}