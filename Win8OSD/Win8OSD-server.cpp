#include <QDebug>
#include <QGuiApplication>
#include <QLocalServer>
#include <QLocalSocket>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QScreen>
#include <QTimer>
#include <QWindow>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>

// 🧩 LayerShellQt
#include <LayerShellQt/window.h>

const QString socketName = "osd_instance_socket";

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    // Default context values
    QString mode = "volume";
    int value = 50;
    bool isMuted = false;

    QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QDir hexDir(QDir(configDir).filePath("hexlauncher"));
    QString configPath = hexDir.filePath("apps.ini");

    QSettings settings(configPath, QSettings::IniFormat);


    // Read all keys in the [gen] group
    settings.beginGroup("gen");

    QVariantMap AppModel;

    if (!settings.childKeys().isEmpty()) {
        AppModel["HexWidth"] = settings.value("HexWidth", 200).toInt();
        AppModel["HexHeight"] = settings.value("HexHeight", 220).toInt();
        AppModel["HexMargin"] = settings.value("HexMargin", 12).toInt();
        AppModel["BorderWidth"] = settings.value("BorderWidth", 4).toInt();
        AppModel["IconGrid"] = settings.value("IconGrid", 5).toInt();
        AppModel["IconPpage"] = settings.value("IconPpage", 14).toInt();
        AppModel["Color"] = settings.value("Color", "#1b1f2a").toString();
        AppModel["BorderColor"] = settings.value("BorderColor", "#FF00FFFF").toString();
        AppModel["HoveredColor"] = settings.value("HoveredColor", "#d900ff00").toString();
        AppModel["BorderHoveredColor"] = settings.value("BorderHoveredColor", "red").toString();
        AppModel["AnimationDuration"] = settings.value("AnimationDuration", 300).toInt();
        AppModel["AnimationScale"] = settings.value("AnimationScale", 1.05).toDouble();
        AppModel["mainFont"] = settings.value("mainFont", "Transducer test").toString();
        AppModel["subFont"] = settings.value("subFont", "Roboto").toString();
    } else {
        qWarning() << "No [gen] group found in" << configPath;
    }

    settings.endGroup();

    // Expose AppModel map to QML
    engine.rootContext()->setContextProperty("AppModel", QVariant::fromValue(AppModel));

    // Set context properties
    engine.rootContext()->setContextProperty("osdMode", mode);
    engine.rootContext()->setContextProperty("osdValue", value);
    engine.rootContext()->setContextProperty("osdMuted", isMuted);

    // Load embedded QML
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty()) {
        qCritical("Failed to load QML.");
        return -1;
    }

    // Get root QWindow
    QObject* root = engine.rootObjects().first();
    QWindow* window = qobject_cast<QWindow*>(root);
    if (!window) {
        qCritical("Root object is not a QWindow.");
        return -1;
    }

    // 🧩 Register with LayerShellQt
    auto layerWindow = LayerShellQt::Window::get(window);
    layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);
    layerWindow->setKeyboardInteractivity(
        LayerShellQt::Window::KeyboardInteractivityNone);
    layerWindow->setAnchors({
        // LayerShellQt::Window::AnchorBottom,
        LayerShellQt::Window::AnchorLeft
    });
    layerWindow->setExclusiveZone(-1);
    layerWindow->setMargins({200, 0, 0, 0});

    window->setFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);

    // Start hidden
    window->hide();

    // Auto-hide after 1.5 seconds
    QTimer timer;
    timer.setInterval(1500);
    timer.setSingleShot(true);
    QObject::connect(&timer, &QTimer::timeout, [&]() {
        window->hide();
    });

    // Local socket server setup
    QLocalServer server;
    QLocalServer::removeServer(socketName);
    if (!server.listen(socketName)) {
        qCritical() << "Failed to start socket server on" << socketName;
        return 1;
    }

    QObject::connect(&server, &QLocalServer::newConnection, [&]() {
        QLocalSocket* client = server.nextPendingConnection();
        if (client->waitForReadyRead(500)) {
            QStringList parts = QString(client->readAll()).split(' ');
            if (parts.size() >= 2) {
                root->setProperty("mode", parts[0]);
                root->setProperty("value", parts[1].toInt());
                if (parts.size() >= 3)
                    root->setProperty("muted", parts[2] == "1");

                // Show and center the window
                window->show();
                QScreen* screen = window->screen();
                if (screen) {
                    QRect screenGeometry = screen->geometry();
                    int x = screenGeometry.x() + (screenGeometry.width() - window->width()) / 2;
                    int y = screenGeometry.y() + (screenGeometry.height() - window->height()) / 2;
                    window->setPosition(x, y);
                }

                window->raise();
                window->requestActivate();
                timer.start();
            }
        }
        client->disconnectFromServer();
    });

    return app.exec();
}
