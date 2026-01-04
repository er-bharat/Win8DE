#include <QDebug>
#include <QGuiApplication>
#include <QLocalServer>
#include <QLocalSocket>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QScreen>
#include <QTimer>
#include <QWindow>

// 🧩 LayerShellQt
#include <LayerShellQt/window.h>

const QString socketName = "osd_instance_socket";

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    // Default OSD state
    QString mode = "volume";
    int value = 50;
    bool isMuted = false;

    // OSD properties
    engine.rootContext()->setContextProperty("osdMode", mode);
    engine.rootContext()->setContextProperty("osdValue", value);
    engine.rootContext()->setContextProperty("osdMuted", isMuted);

    // Load QML
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty()) {
        qCritical("Failed to load QML.");
        return -1;
    }

    // Root window
    QObject* root = engine.rootObjects().first();
    QWindow* window = qobject_cast<QWindow*>(root);
    if (!window) {
        qCritical("Root object is not a QWindow.");
        return -1;
    }

    // -------------------------------
    // LayerShell setup
    // -------------------------------
    auto layerWindow = LayerShellQt::Window::get(window);
    layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);
    layerWindow->setKeyboardInteractivity(
        LayerShellQt::Window::KeyboardInteractivityNone);
    layerWindow->setAnchors({
        LayerShellQt::Window::AnchorLeft
    });
    layerWindow->setExclusiveZone(-1);
    layerWindow->setMargins({200, 0, 0, 0});

    window->setFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
    window->hide();

    // Auto-hide timer
    QTimer timer;
    timer.setInterval(1500);
    timer.setSingleShot(true);
    QObject::connect(&timer, &QTimer::timeout, [&]() {
        window->hide();
    });

    // -------------------------------
    // Local socket server
    // -------------------------------
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

                window->show();

                if (QScreen* screen = window->screen()) {
                    QRect g = screen->geometry();
                    window->setPosition(
                        g.x() + (g.width() - window->width()) / 2,
                                        g.y() + (g.height() - window->height()) / 2
                    );
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
