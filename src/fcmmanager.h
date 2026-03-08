#ifndef FCMMANAGER_H
#define FCMMANAGER_H

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QPointer>
#include "lib/securestorage.h"
#include "lib/apiservice.h"

class FCMManager : public QObject {
    Q_OBJECT
public:
    explicit FCMManager(SecureStorage *storage, QObject *parent = nullptr);
    void updateTokenOnBackend(const QString &token);
    static FCMManager* instance();
    void processIncomingSignal(const QString &roomId, const QString &email);
    void processCallEndingSignal(const QString &email);

signals:
    // Signal to notify the Backend or UI of an incoming call
    void callSignalReceived(const QString &roomId, const QString &email);
    void fcmTokenReceived(const QString &token);
    void callEndingSignal();

private:
    static FCMManager* s_instance;
    QPointer<SecureStorage> m_storage;
    QPointer<APIService> m_api;
};

#endif // FCMMANAGER_H