#include "apiservice.h"

APIService::APIService(QPointer<Settings> settings, QPointer<SecureStorage> storage, QObject *parent) : QObject(parent) {
    this->m_settings = settings;
    this->m_storage = storage;
}

void APIService::update_fcm(QString fcm_token, QString accessToken) {
    QString host = this->m_settings->getHttpProtocol() + "://" + this->m_settings->getHost() + API::FCM::updateDevice;
    QUrl hostUrl(host);
    
    // Helper lambda to construct and send the request
    auto sendReq = [this, fcm_token, hostUrl](QString token) {
        QNetworkRequest request(hostUrl);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("Authorization", "Bearer " + token.toUtf8());

        QJsonObject json;
        json["fcm_token"] = fcm_token;
        return this->m_networkManager.post(request, QJsonDocument(json).toJson(QJsonDocument::Compact));
    };

    QNetworkReply *reply = sendReq(accessToken);
    
    connect(reply, &QNetworkReply::finished, this, [this, reply, sendReq]() {
        int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (reply->error() == QNetworkReply::NoError) {
            qDebug() << "FCM Token Updated";
        } else if (statusCode == 401) {
            qDebug() << "Unauthorized! Refreshing Access Token for FCM Update...";
            
            // SingleShot connection for successful refresh
            connect(this, &APIService::tokenRefreshed, this, [this, sendReq](QString newAccess, QString) {
                QNetworkReply *retryReply = sendReq(newAccess);
                connect(retryReply, &QNetworkReply::finished, this, [this, retryReply]() {
                    int retryCode = retryReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
                    if (retryReply->error() == QNetworkReply::NoError) {
                        qDebug() << "FCM Token Updated (Retry)";
                    } else if (retryCode == 401) {
                        emit this->invalidSession();
                    }
                    retryReply->deleteLater();
                });
            }, Qt::SingleShotConnection);
            
            // SingleShot connection for failed refresh
            connect(this, &APIService::tokenRefreshError, this, [this](QString error) {
                qDebug() << "FCM Token Update Failed during refresh:" << error;
                emit this->invalidSession();
            }, Qt::SingleShotConnection);
            
            this->refreshToken();
        }
        reply->deleteLater();
    });
}

void APIService::get_room(QString email, QString accessToken) {
    QString hostUrl = this->m_settings->getHttpProtocol() + "://" + this->m_settings->getHost() + API::Voice::call;
    QUrl url(hostUrl);
    
    // Helper lambda to construct and send the request
    auto sendReq = [this, email, url](QString token) {
        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("Authorization", "Bearer " + token.toUtf8());

        QJsonObject json;
        json["email"] = email;
        return m_networkManager.post(request, QJsonDocument(json).toJson(QJsonDocument::Compact));
    };

    // Helper lambda to parse the response
    auto handleResponse = [this](QNetworkReply *reply) -> bool {
        int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (statusCode == 401) {
            return false; // False indicates we need to refresh and retry
        }

        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "Failed to retrieve RoomID:" << reply->errorString();
            emit this->roomFetchError("Failed to connect to the server");
            return true;
        }

        QByteArray responseData = reply->readAll();
        QJsonParseError parseError;
        QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData, &parseError);

        if (parseError.error != QJsonParseError::NoError || !jsonDoc.isObject()) {
            qDebug() << "JSON Parse Error:" << parseError.errorString();
            emit this->roomFetchError("Failed to connect to the server");
            return true;
        }

        QJsonObject jsonObj = jsonDoc.object();
        if (!jsonObj.contains("data")) {
            qDebug() << "JSON doesn't contains `data` key";
            emit this->roomFetchError("Failed to connect to the server");
            return true;
        }

        QJsonObject dataJson = jsonObj.value("data").toObject();
        if (!dataJson.contains("room_id") || !dataJson.contains("room_name")) {
            qDebug() << "Missing `room_id` or `room_name` keys";
            emit this->roomFetchError("Failed to connect to the server");
            return true;
        }

        QString roomId = dataJson.value("room_id").toString();
        QString roomName = dataJson.value("room_name").toString();
        emit this->roomFetched(roomId, roomName);
        return true; // True indicates the request has been fully processed
    };

    QNetworkReply *reply = sendReq(accessToken);
    connect(reply, &QNetworkReply::finished, this, [this, reply, sendReq, handleResponse]() {
        bool done = handleResponse(reply);
        if (!done) {
            qDebug() << "Unauthorized! Refreshing Access Token for Room Fetch...";
            
            connect(this, &APIService::tokenRefreshed, this, [this, sendReq, handleResponse](QString newAccess, QString) {
                QNetworkReply *retryReply = sendReq(newAccess);
                connect(retryReply, &QNetworkReply::finished, this, [this, retryReply, handleResponse]() {
                    bool retryDone = handleResponse(retryReply);
                    if (!retryDone) {
                        emit this->invalidSession(); // Failed 401 again
                    }
                    retryReply->deleteLater();
                });
            }, Qt::SingleShotConnection);
            
            connect(this, &APIService::tokenRefreshError, this, [this](QString error) {
                qDebug() << "Fetching Room Details Failed:" << error;
                emit this->invalidSession();
            }, Qt::SingleShotConnection);
            
            this->refreshToken();
        }
        reply->deleteLater();
    });
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
    QString hostUrl = this->m_settings->getHttpProtocol() + "://" + this->m_settings->getHost() + API::Voice::endCall;
    QUrl url(hostUrl);
    
    // Helper lambda to construct and send the request
    auto sendReq = [this, email, url](QString token) {
        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setRawHeader("Authorization", "Bearer " + token.toUtf8());

        QJsonObject json;
        json["email"] = email;
        return m_networkManager.sendCustomRequest(request, "DELETE", QJsonDocument(json).toJson(QJsonDocument::Compact));
    };

    // Helper lambda to parse the response
    auto handleResponse = [this](QNetworkReply *reply) -> bool {
        int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (statusCode == 401) {
            return false; // Requires retry
        }

        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "Failed to process ending call request:" << reply->errorString();
            emit this->roomFetchError("Failed to connect to the server");
            return true;
        }

        QByteArray responseData = reply->readAll();
        QJsonParseError parseError;
        QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData, &parseError);

        if (parseError.error != QJsonParseError::NoError || !jsonDoc.isObject()) {
            qDebug() << "JSON Parse Error:" << parseError.errorString();
            emit this->roomFetchError("Failed to connect to the server");
            return true;
        }

        QJsonObject jsonObj = jsonDoc.object();
        if (!jsonObj.contains("status")) {
            qDebug() << "JSON doesn't contains `status` key";
            emit this->roomFetchError("Failed to connect to the server");
            return true;
        }

        if (jsonObj.value("status").toBool()) {
            emit this->endCallSuccess();
        } else {
            emit this->endCallFailed();
        }
        return true;
    };

    QNetworkReply *reply = sendReq(accessToken);
    connect(reply, &QNetworkReply::finished, this, [this, reply, sendReq, handleResponse]() {
        bool done = handleResponse(reply);
        if (!done) {
            qDebug() << "Unauthorized! Refreshing Access Token for End Call...";
            
            connect(this, &APIService::tokenRefreshed, this, [this, sendReq, handleResponse](QString newAccess, QString) {
                QNetworkReply *retryReply = sendReq(newAccess);
                connect(retryReply, &QNetworkReply::finished, this, [this, retryReply, handleResponse]() {
                    bool retryDone = handleResponse(retryReply);
                    if (!retryDone) {
                        emit this->invalidSession(); // Failed 401 again
                    }
                    retryReply->deleteLater();
                });
            }, Qt::SingleShotConnection);
            
            connect(this, &APIService::tokenRefreshError, this, [this](QString error) {
                qDebug() << "Sending call termination request Failed:" << error;
                emit this->invalidSession();
            }, Qt::SingleShotConnection);
            
            this->refreshToken();
        }
        reply->deleteLater();
    });
}
