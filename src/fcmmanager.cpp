#include "fcmmanager.h"
#include <QDebug>
#include <QJniObject>
#include <QJsonObject>
#include <QJsonDocument>
#include <QNetworkReply>

FCMManager* FCMManager::s_instance = nullptr;

FCMManager::FCMManager(SecureStorage *storage, QObject *parent) : QObject(parent) {
    s_instance = this;
    this->m_storage = storage;
}

FCMManager* FCMManager::instance() {
    return s_instance;
}

void FCMManager::processIncomingSignal(const QString &roomId, const QString &email) {
    qDebug() << "FCMManager: Received call from" << email;
    emit callSignalReceived(roomId, email);
}

void FCMManager::processCallEndingSignal(const QString &email) {
    qDebug() << "FCMManager: Received call ending signal";
    emit callEndingSignal();
}

// JNI Bridge: Matches the native method in MyFirebaseMessagingService.java
extern "C" {
    JNIEXPORT void JNICALL Java_com_github_biltudas1_dialsome_MyFirebaseMessagingService_onCallMessageReceive(
        JNIEnv* env, jobject, jstring roomId, jstring email) {
        
        FCMManager* manager = FCMManager::instance();
        if (!manager) {
            qDebug() << "FCMManager instance not initialized!";
            return;
        }

        QString roomStr = QJniObject(roomId).toString();
        QString emailStr = QJniObject(email).toString();

        // Invoke on the main thread to safely emit signals and update UI
        QMetaObject::invokeMethod(manager, [=]() {
            manager->processIncomingSignal(roomStr, emailStr);
        }, Qt::QueuedConnection);
    }
}

extern "C" {
    JNIEXPORT void JNICALL Java_com_github_biltudas1_dialsome_MyFirebaseMessagingService_notifyNewToken(
        JNIEnv* env, jobject, jstring token) {
        
        QString tokenStr = QJniObject(token).toString();
        QMetaObject::invokeMethod(FCMManager::instance(), [=]() {
            FCMManager::instance()->updateTokenOnBackend(tokenStr);
        }, Qt::QueuedConnection);
    }
}

extern "C" {
    JNIEXPORT void JNICALL Java_com_github_biltudas1_dialsome_MyFirebaseMessagingService_onCallMessageEnd(
        JNIEnv* env, jobject, jstring email) {
        
        QString emailStr = QJniObject(email).toString();
        QMetaObject::invokeMethod(FCMManager::instance(), [=]() {
            FCMManager::instance()->processCallEndingSignal(emailStr);
        }, Qt::QueuedConnection);
    }
}

void FCMManager::updateTokenOnBackend(const QString &token) {
    this->m_storage->save("fcm_token", token);
    QString userId = this->m_storage->get("id");
    if (userId.isEmpty()) {
        qDebug() << "User not logged in yet. FCM token cached locally.";
        return;
    }

    qDebug() << "FCM Token:" << token;
    this->fcmTokenReceived(token);
}
