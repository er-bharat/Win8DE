#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QLocalServer>
#include <QLocalSocket>
#include <QTimer>
#include <QWindow>
#include <LayerShellQt/window.h>

static constexpr auto socketName = "osd_instance_socket";
static constexpr int AUTOHIDE_MS = 1500;
static constexpr int IDLE_TIMEOUT_MS = 3000;

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    
    // Default OSD state
    engine.rootContext()->setContextProperty("osdMode", "brightness");
    engine.rootContext()->setContextProperty("osdValue", 50);
    engine.rootContext()->setContextProperty("osdMuted", false);
    
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;
    
    auto *window = qobject_cast<QWindow *>(engine.rootObjects().first());
    if (!window) return -1;
    
    // LayerShell setup
    auto *layer = LayerShellQt::Window::get(window);
    layer->setLayer(LayerShellQt::Window::LayerOverlay);
    layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
    layer->setAnchors({LayerShellQt::Window::AnchorLeft});
    layer->setMargins({200, 0, 0, 0});
    layer->setExclusiveZone(-1);
    
    window->setFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
    window->hide();
    
    // Auto-hide OSD timer
    QTimer hideTimer;
    hideTimer.setInterval(AUTOHIDE_MS);
    hideTimer.setSingleShot(true);
    QObject::connect(&hideTimer, &QTimer::timeout, window, &QWindow::hide);
    
    // Idle exit timer
    QTimer idleTimer;
    idleTimer.setInterval(IDLE_TIMEOUT_MS);
    idleTimer.setSingleShot(true);
    QObject::connect(&idleTimer, &QTimer::timeout, &app, &QCoreApplication::quit);
    
    // Local socket server
    QLocalServer server;
    QLocalServer::removeServer(socketName);
    if (!server.listen(socketName)) {
        qCritical() << "OSD server already running";
        return 1;
    }
    
    QObject::connect(&server, &QLocalServer::newConnection, [&]() {
        auto *client = server.nextPendingConnection();
        
        QObject::connect(client, &QLocalSocket::readyRead, [&, client]() {
            const QString data = QString::fromUtf8(client->readAll()).trimmed();
            const QStringList parts = data.split(' ', Qt::SkipEmptyParts);
            if (parts.size() < 2) return;
            
            engine.rootContext()->setContextProperty("osdMode", parts[0]);
            engine.rootContext()->setContextProperty("osdValue", parts[1].toInt());
            engine.rootContext()->setContextProperty("osdMuted", parts.value(2) == "1");
            
            window->show();
            hideTimer.start();
            idleTimer.start(); // reset idle timer
            
            client->disconnectFromServer();
        });
    });
    
    return app.exec();
}
