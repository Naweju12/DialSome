cmake_minimum_required(VERSION 3.16)
project(DialSome LANGUAGES CXX)

# Extra Metadatas
add_definitions(-DGITHUB_REPO="https://github.com/BiltuDas1/DialSome")
add_definitions(-DDIALSOME_SERVER="dialsome.onrender.com")
add_definitions(-DHTTPS=true)
add_definitions(-DWSS=true)

find_package(Qt6 REQUIRED COMPONENTS
    Quick
    QuickControls2
    Network
    WebSockets
    Multimedia
    Core5Compat
)

qt_standard_project_setup(REQUIRES 6.8)

# OpenSSL
if (ANDROID)
    include(${CMAKE_CURRENT_SOURCE_DIR}/libraries/android_openssl/android_openssl.cmake)
else()
    find_package(OpenSSL REQUIRED)
endif()

qt_add_executable(DialSome
    main.cpp
)

if (ANDROID)
    add_android_openssl_libraries(DialSome)
endif()

set_source_files_properties(ui/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(DialSome
    URI DialSome
    VERSION 1.0
    QML_FILES
        Main.qml
        ui/Theme.qml
        ui/LoginPage.qml
        ui/MainPage.qml
        ui/IncomingCallPage.qml
        ui/CallingPage.qml
        ui/SettingsPage.qml
        ui/SelectContactPage.qml
        ui/ThemedIcon.qml
    SOURCES
        src/lib/securestorage.h src/lib/securestorage.cpp
        src/lib/google.h src/lib/google.cpp
        src/lib/settings.h src/lib/settings.cpp
        src/lib/apiservice.h src/lib/apiservice.cpp
        src/lib/apiconstrains.h
        src/utils.h src/utils.cpp
        src/fcmmanager.h src/fcmmanager.cpp
        src/backend.h src/backend.cpp
    RESOURCES
        icons/logo.png
        icons/dial.png
        icons/user.png
        icons/settings.png
        icons/server.png
        icons/add.png
        icons/block.png
        icons/volume_on.png
        icons/volume_off.png
        icons/mic_on.png
        icons/mic_off.png
        sounds/ringback.wav
)

qt_add_resources(DialSome "configs"
    PREFIX "/"
    FILES qtquickcontrols2.conf
)

target_link_libraries(DialSome PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
    Qt6::WebSockets
    Qt6::Multimedia
    Qt6::Core5Compat
)

target_include_directories(DialSome PRIVATE src src/lib)

if(ANDROID)
    set_property(TARGET DialSome PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
        ${CMAKE_CURRENT_SOURCE_DIR}/android)
endif()

if(ANDROID AND NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    set_target_properties(DialSome PROPERTIES INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
    
    # This forces the linker to strip all debug symbols
    target_link_options(DialSome PRIVATE "-Wl,--strip-all")
endif()

if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_definitions(-DQT_NO_DEBUG_OUTPUT)
    set(QT_QML_DEBUG OFF)
endif()
