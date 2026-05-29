#include "utils.h"

Utils::Utils(QObject *parent) : QObject(parent) {}

void Utils::showToast(const QString &message) {
  #ifdef Q_OS_ANDROID
      // Retrieve the current Android activity instance from the Qt framework
      QJniObject activity = QNativeInterface::QAndroidApplication::context();
      
      if (activity.isValid()) {
          QJniObject javaMessage = QJniObject::fromString(message);
          
          // Call the static Java method in your new AndroidUtils class
          QJniObject::callStaticMethod<void>(
              "com/github/biltudas1/dialsome/AndroidUtils",
              "showToast",
              "(Landroid/app/Activity;Ljava/lang/String;)V",
              activity.object<jobject>(),
              javaMessage.object<jstring>()
          );
      }
  #else
      // Fallback for desktop testing
      qDebug() << "Toast message:" << message;
  #endif
}

void Utils::createFile(const QString &fileName, const QString &content) {
    QString path = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/" + fileName;
    QFile file(path);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        out << content;
        file.close();
    }
}

void Utils::moveToBackground() {
#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (activity.isValid()) {
        activity.callMethod<jboolean>("moveTaskToBack", "(Z)Z", true);
    }
#else
    qDebug() << "moveToBackground: not supported on this platform";
#endif
}
