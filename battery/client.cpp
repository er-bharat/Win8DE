#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>
#include <QWindow>

#include <LayerShellQt/window.h>

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);

  QString event = (argc > 1) ? argv[1] : "";

  qDebug() << "Battery client event:" << event;

  QQmlApplicationEngine engine;

  // Pass event to QML
  engine.rootContext()->setContextProperty("eventType", event);

  engine.load(QUrl("qrc:/main.qml"));

  if (engine.rootObjects().isEmpty())
    return -1;

  // Get window
  QWindow *window = qobject_cast<QWindow *>(engine.rootObjects().first());
  if (!window)
    return -1;

  // 🧩 LayerShell setup (Wayland overlay)
  auto layerWindow = LayerShellQt::Window::get(window);
  layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);
  layerWindow->setKeyboardInteractivity(
      LayerShellQt::Window::KeyboardInteractivityNone);

  // Position (left side like your earlier setup)
  layerWindow->setAnchors({LayerShellQt::Window::AnchorLeft});
  layerWindow->setMargins({400, 0, 0, 0});

  layerWindow->setExclusiveZone(-1);

  window->show();

  // ⏳ Auto exit after 5 sec (important for daemon-triggered apps)
  QTimer::singleShot(5000, &app, &QCoreApplication::quit);

  return app.exec();
}
