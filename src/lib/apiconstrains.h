#include <QString>


namespace API {
  const QString sourceRepo = GITHUB_REPO;

  namespace Voice {
    const QString call = "/voicecall/send";
    const QString endCall = "/voicecall/endcall";
  }

  namespace Auth {
    const QString loginUser = "/users/login";
    const QString registerUser = "/users/register";
    const QString refresh = "/token/refresh";
  }

  namespace FCM {
    const QString updateDevice = "/users/fcm/update";
  }

  namespace Contact {
    const QString contactList = "/users/contacts";
  }
}
