#include "app.h"

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QDebug>

void run_qapplication() {
    int argc = 1;
    char *argv[] = { (char*)"upstray", nullptr };

    // Initialize the Qt application as QApplication (needed for widgets like QSystemTrayIcon in QML)
    QApplication app(argc, argv);

    // Ties the window to resources/upstray.desktop so the shell can resolve our
    // icon and name. Without it the taskbar entry has no icon association.
    QGuiApplication::setDesktopFileName("upstray");

    QQmlApplicationEngine engine;

    const QUrl url("qrc:/qt/qml/com/upstray/app/qml/main.qml");
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    // Enter the Qt event loop
    app.exec();
}
