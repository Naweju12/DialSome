#ifndef UTILS_H
#define UTILS_H

#include <QObject>
#include <QJniObject>
#include <QString>
#include <QtQmlIntegration/qqmlintegration.h>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QCoreApplication>

class Utils : public QObject {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit Utils(QObject *parent = nullptr);
    Q_INVOKABLE void showToast(const QString &message);
    Q_INVOKABLE void createFile(const QString &fileName, const QString &content);
    Q_INVOKABLE void moveToBackground();
};

#endif // UTILS_H
