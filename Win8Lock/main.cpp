#include "lockmanager.h"

#include <LayerShellQt/window.h>

#include <QDebug>
#include <QFileInfo>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>
#include <QSharedMemory>

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);

    // ----- Single Instance Check -----
    QSharedMemory sharedMemory("Win8LockSingleton");
    if (!sharedMemory.create(1)) {
        qWarning() << "Another instance of Win8Lock is already running.";
        return 0;
    }


    // ----- QML File Selection -----
    QString qmlFile = "qrc:/New/main.qml";
    QString customPath;

    for (int i = 1; i < argc; ++i) {
        if ((QString(argv[i]) == "-c" || QString(argv[i]) == "--config")) {
            if (i + 1 < argc) {
                QFileInfo fileInfo(argv[i + 1]);
                if (fileInfo.exists() && fileInfo.isFile()) {
                    customPath = QUrl::fromLocalFile(
                        fileInfo.absoluteFilePath()).toString();
                } else {
                    qWarning() << "Custom QML file not found:" << argv[i + 1];
                }
            } else {
                qWarning() << "No config file specified after" << argv[i];
            }
            break;
        }
    }

    QQmlApplicationEngine engine;

    // ----- Lock Manager -----
    LockManager lockManager;
    engine.rootContext()->setContextProperty("lockManager", &lockManager);

    // ----- User Info -----
    QString userName = qgetenv("USER");
    if (userName.isEmpty())
        userName = qgetenv("USERNAME");

    engine.rootContext()->setContextProperty("systemUsername", userName);

    QString avatarPath =
    QString("/var/lib/AccountsService/icons/%1").arg(userName);

    QString avatarUrl;
    if (QFileInfo::exists(avatarPath)) {
        avatarUrl = QUrl::fromLocalFile(avatarPath).toString();
    } else {
        qWarning() << "No avatar found for user:" << userName;
        avatarUrl = "qrc:/images/default-avatar.png";
    }

    engine.rootContext()->setContextProperty("userAvatar", avatarUrl);

    // =========================================================
    // Win8Settings: COLORS + LOCKSCREEN WALLPAPER ONLY
    // =========================================================

    QString win8SettingsPath =
    QDir(QStandardPaths::writableLocation(
        QStandardPaths::ConfigLocation))
    .filePath("Win8Settings/settings.ini");

    QSettings win8Settings(win8SettingsPath, QSettings::IniFormat);

    // ----- Colors -----
    QVariantMap Win8Colors;
    win8Settings.beginGroup("Colors");

    Win8Colors["background"] =
    win8Settings.value("Background", "#000000").toString();
    Win8Colors["tile"] =
    win8Settings.value("Tile", "#ffffff").toString();
    Win8Colors["tileHighlight"] =
    win8Settings.value("TileHighlight", "#ff0000").toString();

    win8Settings.endGroup();

    engine.rootContext()->setContextProperty(
        "Win8Colors", QVariant::fromValue(Win8Colors));

    // ----- Lockscreen wallpaper ONLY -----
    QString lockscreenWallpaper;

    win8Settings.beginGroup("Wallpaper");
    QString lockscreenPath =
    win8Settings.value("Lockscreen").toString();
    win8Settings.endGroup();

    if (!lockscreenPath.isEmpty() && QFileInfo::exists(lockscreenPath)) {
        lockscreenWallpaper =
        QUrl::fromLocalFile(lockscreenPath).toString();
    } else {
        qWarning() << "Lockscreen wallpaper not found.";
    }

    engine.rootContext()->setContextProperty(
        "wallpaperPath", lockscreenWallpaper);

    // ----- Load QML -----
    QUrl qmlUrl =
    customPath.isEmpty() ? QUrl(qmlFile) : QUrl(customPath);

    engine.load(qmlUrl);

    if (engine.rootObjects().isEmpty() && !customPath.isEmpty()) {
        qWarning() << "Failed to load custom QML, falling back.";
        engine.load(QUrl(qmlFile));
    }

    if (engine.rootObjects().isEmpty())
        return -1;

    // ----- LayerShell setup -----
    QQuickWindow* window =
    qobject_cast<QQuickWindow*>(engine.rootObjects().first());

    auto layerWindow = LayerShellQt::Window::get(window);
    layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);
    layerWindow->setScope("lockscreen");
    layerWindow->setKeyboardInteractivity(
        LayerShellQt::Window::KeyboardInteractivityExclusive);
    layerWindow->setAnchors({
        LayerShellQt::Window::AnchorTop,
        LayerShellQt::Window::AnchorBottom,
        LayerShellQt::Window::AnchorLeft,
        LayerShellQt::Window::AnchorRight
    });
    layerWindow->setExclusiveZone(0);

    window->setFlags(Qt::Window
    | Qt::FramelessWindowHint
    | Qt::WindowStaysOnTopHint);

    window->show();

    return app.exec();
}
