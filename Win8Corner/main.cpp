#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QQuickWindow>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QFileSystemWatcher>
#include <QScreen>
#include <LayerShellQt/window.h>

/* ---------------- HotCorner launcher ---------------- */

class HotCornerLauncher : public QObject {
    Q_OBJECT
public:
    explicit HotCornerLauncher(QObject* parent = nullptr) : QObject(parent) {}
    
    Q_INVOKABLE void launch(const QString& command) {
        if (!command.isEmpty()) {
            QProcess::startDetached(command);
        }
    }
};

/* ---------------- Data structs ---------------- */

struct CornerWindow {
    QQuickWindow* window = nullptr;
    QString command;
};

/* ---------------- Config helpers ---------------- */

static QString configFilePath()
{
    return QStandardPaths::writableLocation(
        QStandardPaths::AppConfigLocation
    ) + "/hotcorners.ini";
}

/* Resolve monitor:
 * - Try config
 * - Fallback to first screen
 * - Save fallback into config
 */
static QScreen* resolveTargetScreen()
{
    QSettings settings(configFilePath(), QSettings::IniFormat);
    QString wanted = settings.value("General/Monitor").toString().trimmed();
    
    const QList<QScreen*> screens = QGuiApplication::screens();
    if (screens.isEmpty())
        return nullptr;
    
    if (!wanted.isEmpty()) {
        for (QScreen* s : screens) {
            if (s->name() == wanted)
                return s;
        }
    }
    
    QScreen* fallback = screens.first();
    settings.setValue("General/Monitor", fallback->name());
    settings.sync();
    
    qDebug() << "Monitor not set, using:" << fallback->name();
    return fallback;
}

/* ---------------- Window creation ---------------- */

static QQuickWindow* createWindow(
    QQmlApplicationEngine& engine,
    const QUrl& qml,
    const QString& cmd,
    LayerShellQt::Window::Anchors anchors,
    QScreen* screen
) {
    QQmlComponent component(&engine, qml);
    QObject* obj = component.create();
    if (!obj) {
        qWarning() << "Failed to create QML:" << component.errors();
        return nullptr;
    }
    
    auto* window = qobject_cast<QQuickWindow*>(obj);
    if (!window) {
        qFatal("Root QML object must be Window");
    }
    
    auto layer = LayerShellQt::Window::get(window);
    layer->setLayer(LayerShellQt::Window::LayerOverlay);
    layer->setAnchors(anchors);
    layer->setExclusiveZone(-1);
    layer->setKeyboardInteractivity(
        LayerShellQt::Window::KeyboardInteractivityNone
    );
    
    window->setFlags(
        Qt::FramelessWindowHint |
        Qt::WindowStaysOnTopHint |
        Qt::BypassWindowManagerHint
    );
    
    if (screen) {
        window->setScreen(screen);   // ✅ correct API for your LayerShellQt
    }
    
    window->setProperty("cornerCommand", cmd);
    window->show();
    return window;
}

/* ---------------- Load corner commands ---------------- */

static void loadCornerCommands(
    const QString& iniFile,
    CornerWindow& topLeft,
    CornerWindow& topRight,
    CornerWindow& bottomLeft,
    CornerWindow& bottomRight
) {
    QSettings settings(iniFile, QSettings::IniFormat);
    settings.beginGroup("Corners");
    
    topLeft.command     = settings.value("TopLeft").toString();
    topRight.command    = settings.value("TopRight").toString();
    bottomLeft.command  = settings.value("BottomLeft").toString();
    bottomRight.command = settings.value("BottomRight").toString();
    
    settings.endGroup();
    
    if (topLeft.window)     topLeft.window->setProperty("cornerCommand", topLeft.command);
    if (topRight.window)    topRight.window->setProperty("cornerCommand", topRight.command);
    if (bottomLeft.window)  bottomLeft.window->setProperty("cornerCommand", bottomLeft.command);
    if (bottomRight.window) bottomRight.window->setProperty("cornerCommand", bottomRight.command);
}

/* ---------------- main ---------------- */

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    
    QString iniFile = configFilePath();
    QDir().mkpath(QFileInfo(iniFile).absolutePath());
    
    /* Create default config if missing */
    if (!QFile::exists(iniFile)) {
        QSettings settings(iniFile, QSettings::IniFormat);
        
        settings.beginGroup("General");
        settings.setValue("Monitor", "");   // auto-filled on first run
        settings.endGroup();
        
        settings.beginGroup("Corners");
        settings.setValue("TopLeft", "Win8Running");
        settings.setValue("TopRight", "firefox");
        settings.setValue("BottomLeft", "pcmanfm-qt");
        settings.setValue("BottomRight", "Win8Start");
        settings.endGroup();
        
        settings.sync();
    }
    
    HotCornerLauncher launcher;
    engine.rootContext()->setContextProperty(
        "hotCornerLauncher",
        &launcher
    );
    
    /* Resolve monitor once */
    QScreen* targetScreen = resolveTargetScreen();
    
    /* Create corner windows */
    CornerWindow topLeft{
        createWindow(
            engine,
            QUrl(QStringLiteral("qrc:/main1.qml")),
                     "",
                     LayerShellQt::Window::Anchors(
                         LayerShellQt::Window::AnchorTop |
                         LayerShellQt::Window::AnchorLeft
                     ),
                     targetScreen
        )
    };
    
    CornerWindow topRight{
        createWindow(
            engine,
            QUrl(QStringLiteral("qrc:/main2.qml")),
                     "",
                     LayerShellQt::Window::Anchors(
                         LayerShellQt::Window::AnchorTop |
                         LayerShellQt::Window::AnchorRight
                     ),
                     targetScreen
        )
    };
    
    CornerWindow bottomLeft{
        createWindow(
            engine,
            QUrl(QStringLiteral("qrc:/main3.qml")),
                     "",
                     LayerShellQt::Window::Anchors(
                         LayerShellQt::Window::AnchorBottom |
                         LayerShellQt::Window::AnchorLeft
                     ),
                     targetScreen
        )
    };
    
    CornerWindow bottomRight{
        createWindow(
            engine,
            QUrl(QStringLiteral("qrc:/main4.qml")),
                     "",
                     LayerShellQt::Window::Anchors(
                         LayerShellQt::Window::AnchorBottom |
                         LayerShellQt::Window::AnchorRight
                     ),
                     targetScreen
        )
    };
    
    /* Initial load */
    loadCornerCommands(
        iniFile,
        topLeft,
        topRight,
        bottomLeft,
        bottomRight
    );
    
    /* Watch config for changes */
    QFileSystemWatcher watcher;
    watcher.addPath(iniFile);
    
    QObject::connect(
        &watcher,
        &QFileSystemWatcher::fileChanged,
        [&]() {
            loadCornerCommands(
                iniFile,
                topLeft,
                topRight,
                bottomLeft,
                bottomRight
            );
            if (!watcher.files().contains(iniFile))
                watcher.addPath(iniFile);
        }
    );
    
    return app.exec();
}

#include "main.moc"
