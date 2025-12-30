#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSettings>
#include <QStandardPaths>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <LayerShellQt/window.h>
#include <QDebug>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // --------------------------------------------------------
    // Win8Settings path
    // --------------------------------------------------------
    QString settingsPath =
    QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
    + "/Win8Settings/settings.ini";

    // --------------------------------------------------------
    // Helper lambda to load wallpaper
    // --------------------------------------------------------
    auto loadWallpaper = [&](QString &outWallpaper) {
        QSettings settings(settingsPath, QSettings::IniFormat);

        settings.beginGroup("Wallpaper");
        QString desktopPath = settings.value("Desktop").toString();
        settings.endGroup();

        if (!desktopPath.isEmpty() && QFileInfo::exists(desktopPath)) {
            outWallpaper = QUrl::fromLocalFile(desktopPath).toString();
            qDebug() << "🖼 Desktop wallpaper loaded:" << outWallpaper;
        } else {
            qWarning() << "⚠️ Desktop wallpaper not found.";
        }
    };

    QString wallpaperPath;
    loadWallpaper(wallpaperPath);

    engine.rootContext()->setContextProperty("wallpaperPath", wallpaperPath);

    // --------------------------------------------------------
    // File system watcher
    // --------------------------------------------------------
    QFileSystemWatcher watcher;

    if (QFileInfo::exists(settingsPath)) {
        watcher.addPath(settingsPath);
    } else {
        qWarning() << "⚠️ settings.ini not found, watching directory instead.";
        watcher.addPath(QFileInfo(settingsPath).absolutePath());
    }

    QObject::connect(&watcher, &QFileSystemWatcher::fileChanged,
                     [&](const QString &) {
                         qDebug() << "🔄 settings.ini changed, reloading...";
                         loadWallpaper(wallpaperPath);
                         engine.rootContext()->setContextProperty(
                             "wallpaperPath", wallpaperPath);

                         // Re-add watcher (Qt removes it on change)
                         if (!watcher.files().contains(settingsPath)
                             && QFileInfo::exists(settingsPath)) {
                             watcher.addPath(settingsPath);
                             }
                     });

    // --------------------------------------------------------
    // Load QML
    // --------------------------------------------------------
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    engine.load(url);

    if (engine.rootObjects().isEmpty())
        return -1;

    QQuickWindow *window =
    qobject_cast<QQuickWindow*>(engine.rootObjects().first());
    if (!window)
        return -1;

    // --------------------------------------------------------
    // LayerShell
    // --------------------------------------------------------
    auto layerWindow = LayerShellQt::Window::get(window);
    layerWindow->setLayer(LayerShellQt::Window::LayerBackground);
    layerWindow->setKeyboardInteractivity(
        LayerShellQt::Window::KeyboardInteractivityNone);
    layerWindow->setAnchors({
        LayerShellQt::Window::AnchorTop,
        LayerShellQt::Window::AnchorBottom,
        LayerShellQt::Window::AnchorLeft,
        LayerShellQt::Window::AnchorRight
    });
    layerWindow->setExclusiveZone(0);

    window->setFlags(Qt::FramelessWindowHint);
    window->showFullScreen();

    return app.exec();
}
