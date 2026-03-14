#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QString>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QIODevice>
#include <QSettings>
#include <QVariant>
#include <QAnyStringView>

class Settings : public QObject {
    Q_OBJECT

public:
    explicit Settings(QObject *parent = nullptr);
    QString getHost() const;
    QString getHttpProtocol() const;
    QString getWSProtocol() const;
    void save(const QString &key, const QVariant &value);
    QVariant get(const QString &key, const QVariant &defaultValue = QVariant()) const;

private:
    QScopedPointer<QSettings> m_settings;
};

#endif // SETTINGS_H
