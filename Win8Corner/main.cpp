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
#include <LayerShellQt/window.h>

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

// Struct to hold corner windows
struct CornerWindow {
    QQuickWindow* window = nullptr;
    QString command;
};

// Create LayerShell window
static QQuickWindow* createWindow(
    QQmlApplicationEngine& engine,
    const QUrl& qml,
    const QString& cmd,
    LayerShellQt::Window::Anchors anchors
) {
    QQmlComponent component(&engine, qml);
    QObject* obj = component.create();
    if (!obj) {
        qWarning() << "Failed to create QML component:" << component.errors();
        return nullptr;
    }

    auto* window = qobject_cast<QQuickWindow*>(obj);
    if (!window) {
        qFatal("Root item must be a Window");
    }

    auto layer = LayerShellQt::Window::get(window);
    layer->setLayer(LayerShellQt::Window::LayerOverlay);
    layer->setAnchors(anchors);
    layer->setExclusiveZone(-1);
    layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);

    window->setFlags(
        Qt::FramelessWindowHint |
        Qt::WindowStaysOnTopHint |
        Qt::BypassWindowManagerHint
    );

    window->setProperty("cornerCommand", cmd);
    window->show();
    return window;
}

// Load corner commands from INI file
static void loadCornerCommands(
    const QString& iniFile,
    CornerWindow& topLeft,
    CornerWindow& topRight,
    CornerWindow& bottomLeft,
    CornerWindow& bottomRight
) {
    QSettings settings(iniFile, QSettings::IniFormat);
    settings.beginGroup("Corners");
    topLeft.command = settings.value("TopLeft").toString();
    topRight.command = settings.value("TopRight").toString();
    bottomLeft.command = settings.value("BottomLeft").toString();
    bottomRight.command = settings.value("BottomRight").toString();
    settings.endGroup();

    if (topLeft.window) topLeft.window->setProperty("cornerCommand", topLeft.command);
    if (topRight.window) topRight.window->setProperty("cornerCommand", topRight.command);
    if (bottomLeft.window) bottomLeft.window->setProperty("cornerCommand", bottomLeft.command);
    if (bottomRight.window) bottomRight.window->setProperty("cornerCommand", bottomRight.command);
}

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir().mkpath(configDir);
    QString iniFile = configDir + "/hotcorners.ini";

    // Create default INI if missing
    if (!QFile::exists(iniFile)) {
        QSettings settings(iniFile, QSettings::IniFormat);
        settings.beginGroup("Corners");
        settings.setValue("TopLeft", "gnome-terminal");
        settings.setValue("TopRight", "firefox");
        settings.setValue("BottomLeft", "nautilus");
        settings.setValue("BottomRight", "thunderbird");
        settings.endGroup();
        settings.sync();
    }

    HotCornerLauncher launcher;
    engine.rootContext()->setContextProperty("hotCornerLauncher", &launcher);

    // Corner windows
    CornerWindow topLeft{ createWindow(engine, QUrl(QStringLiteral("qrc:/main1.qml")), "", LayerShellQt::Window::Anchors(LayerShellQt::Window::AnchorTop | LayerShellQt::Window::AnchorLeft)) };
    CornerWindow topRight{ createWindow(engine, QUrl(QStringLiteral("qrc:/main2.qml")), "", LayerShellQt::Window::Anchors(LayerShellQt::Window::AnchorTop | LayerShellQt::Window::AnchorRight)) };
    CornerWindow bottomLeft{ createWindow(engine, QUrl(QStringLiteral("qrc:/main3.qml")), "", LayerShellQt::Window::Anchors(LayerShellQt::Window::AnchorBottom | LayerShellQt::Window::AnchorLeft)) };
    CornerWindow bottomRight{ createWindow(engine, QUrl(QStringLiteral("qrc:/main4.qml")), "", LayerShellQt::Window::Anchors(LayerShellQt::Window::AnchorBottom | LayerShellQt::Window::AnchorRight)) };

    // Load commands initially
    loadCornerCommands(iniFile, topLeft, topRight, bottomLeft, bottomRight);

    // Watch for changes
    QFileSystemWatcher watcher;
    watcher.addPath(iniFile);
    QObject::connect(&watcher, &QFileSystemWatcher::fileChanged, [&]() {
        // Reload commands when INI changes
        loadCornerCommands(iniFile, topLeft, topRight, bottomLeft, bottomRight);
        // Re-add path because some editors replace the file instead of editing in-place
        if (!watcher.files().contains(iniFile)) {
            watcher.addPath(iniFile);
        }
    });

    return app.exec();
}

#include "main.moc"
