#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSettings>
#include <QStandardPaths>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QScreen>
#include <LayerShellQt/window.h>
#include <QDebug>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
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
    
    // --------------------------------------------------------
    // Create wallpaper windows for ALL screens
    // --------------------------------------------------------
    QList<QQmlApplicationEngine*> engines;
    
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    
    for (QScreen *screen : QGuiApplication::screens()) {
        
        QQmlApplicationEngine *engine = new QQmlApplicationEngine(&app);
        engines << engine;
        
        engine->rootContext()->setContextProperty(
            "wallpaperPath", wallpaperPath);
        
        engine->load(url);
        if (engine->rootObjects().isEmpty())
            continue;
        
        QQuickWindow *window =
        qobject_cast<QQuickWindow*>(engine->rootObjects().first());
        if (!window)
            continue;
        
        // Bind to this screen
        window->setScreen(screen);
        
        // ----------------------------------------------------
        // LayerShell setup
        // ----------------------------------------------------
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
        window->show();
    }
    
    // --------------------------------------------------------
    // React to wallpaper changes
    // --------------------------------------------------------
    QObject::connect(&watcher, &QFileSystemWatcher::fileChanged,
                     [&](const QString &) {
                         qDebug() << "🔄 settings.ini changed, reloading wallpaper...";
                         
                         loadWallpaper(wallpaperPath);
                         
                         // Update all QML engines
                         for (auto *engine : engines) {
                             engine->rootContext()->setContextProperty(
                                 "wallpaperPath", wallpaperPath);
                         }
                         
                         // Re-add watcher (Qt removes it after change)
                         if (!watcher.files().contains(settingsPath)
                             && QFileInfo::exists(settingsPath)) {
                             watcher.addPath(settingsPath);
                             }
                     });
    
    return app.exec();
}
