#include "settings.h"

Settings::Settings(QObject *parent) : QObject(parent) {
    QString directory = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QString filePath = directory + "/settings.ini";
    
    QDir dir;
    if (!dir.exists(directory)) {
        dir.mkpath(directory);
    }

    if (!QFile::exists(filePath)) {
        QFile file(filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            qDebug() << "Unable to save file: " << filePath;
            return;
        }
        file.write("");
        file.close();
        qDebug() << "File saved successfully at:" << filePath;
    }

    this->m_settings.reset(new QSettings(filePath, QSettings::IniFormat));

    // Default settings
    this->m_settings->setValue("Server/host", DIALSOME_SERVER);
    this->m_settings->setValue("Protocol/https", HTTPS);
    this->m_settings->setValue("Protocol/wss", WSS);
    
    this->m_settings->sync();
}

QString Settings::getHost() const {
    return this->m_settings->value("Server/host").toString();
}

QString Settings::getHttpProtocol() const {
    bool https = this->m_settings->value("Protocol/https").toBool();
    return https ? "https" : "http";
}

QString Settings::getWSProtocol() const {
    bool wss = this->m_settings->value("Protocol/wss").toBool();
    return wss ? "wss" : "ws";
}

void Settings::save(const QString &key, const QVariant &value) {
    if (this->m_settings) {
        this->m_settings->setValue(key, value);
        this->m_settings->sync();
    }
}

QVariant Settings::get(const QString &key, const QVariant &defaultValue) const {
    if (this->m_settings) {
        return this->m_settings->value(key, defaultValue);
    }
    return defaultValue;
}
