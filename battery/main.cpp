#include <LayerShellQt/window.h>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QWindow>

class BatteryDaemon : public QObject {
  Q_OBJECT
  Q_PROPERTY(int percentage READ percentage NOTIFY batteryChanged)
  Q_PROPERTY(bool charging READ charging NOTIFY batteryChanged)
  Q_PROPERTY(bool acConnected READ acConnected NOTIFY acChanged)

public:
  BatteryDaemon(QObject *parent = nullptr) : QObject(parent) {
    qDebug() << "BatteryDaemon starting";
    qDebug() << "DBus system bus connected:"
             << QDBusConnection::systemBus().isConnected();

    detectDevices();
    if (!batteryIface) {
      qWarning() << "❌ No battery device found via UPower";
    }
    if (!lineIface) {
      qWarning() << "⚠ No AC line power device found via UPower";
    }

    // Connect signals
    if (batteryIface) {
      QDBusConnection::systemBus().connect(
          "org.freedesktop.UPower", batteryIface->path(),
          "org.freedesktop.DBus.Properties", "PropertiesChanged", this,
          SLOT(onBatteryChanged(QString, QVariantMap, QStringList)));
      updateBattery();
    }

    if (lineIface) {
      QDBusConnection::systemBus().connect(
          "org.freedesktop.UPower", lineIface->path(),
          "org.freedesktop.DBus.Properties", "PropertiesChanged", this,
          SLOT(onACChanged(QString, QVariantMap, QStringList)));
      updateAC();
    }
  }

  int percentage() const { return m_percentage; }
  bool charging() const { return m_charging; }
  bool acConnected() const { return m_acConnected; }

signals:
  void batteryChanged();
  void lowBattery();
  void fullBattery();
  void acChanged();

private slots:
  void onBatteryChanged(const QString &, const QVariantMap &changed,
                        const QStringList &) {
    if (changed.contains("Percentage") || changed.contains("State")) {
      updateBattery();
    }
  }

  void onACChanged(const QString &, const QVariantMap &changed,
                   const QStringList &) {
    if (changed.contains("Online")) {
      updateAC();
    }
  }

private:
  void detectDevices() {
    QDBusInterface upower("org.freedesktop.UPower", "/org/freedesktop/UPower",
                          "org.freedesktop.UPower",
                          QDBusConnection::systemBus());

    if (!upower.isValid()) {
      qWarning() << "UPower root interface INVALID";
      return;
    }

    QDBusReply<QList<QDBusObjectPath>> reply = upower.call("EnumerateDevices");
    if (!reply.isValid()) {
      qWarning() << "EnumerateDevices failed";
      return;
    }

    for (const QDBusObjectPath &path : reply.value()) {
      QDBusInterface dev("org.freedesktop.UPower", path.path(),
                         "org.freedesktop.UPower.Device",
                         QDBusConnection::systemBus());
      if (!dev.isValid())
        continue;

      int type = dev.property("Type").toInt();
      bool present = dev.property("IsPresent").toBool();

      if (type == 2 && present && !batteryIface) {
        batteryIface = new QDBusInterface("org.freedesktop.UPower", path.path(),
                                          "org.freedesktop.UPower.Device",
                                          QDBusConnection::systemBus(), this);
        qDebug() << "✅ Battery detected at" << path.path();
      }

      if (type == 1 && !lineIface) { // Type 1 = Line Power (AC)
        lineIface = new QDBusInterface("org.freedesktop.UPower", path.path(),
                                       "org.freedesktop.UPower.Device",
                                       QDBusConnection::systemBus(), this);
        qDebug() << "🔌 AC line detected at" << path.path();
      }
    }
  }

  void updateBattery() {
    if (!batteryIface || !batteryIface->isValid())
      return;

    int pct = batteryIface->property("Percentage").toInt();
    int state = batteryIface->property("State").toInt();
    bool chg = (state == 1); // Charging

    if (pct != m_percentage || chg != m_charging) {
      m_percentage = pct;
      m_charging = chg;

      qDebug() << "Battery:" << pct << "%, charging:" << chg;

      emit batteryChanged();

      if (pct <= 20 && !chg) {
        qDebug() << "⚠ Low battery triggered";
        emit lowBattery();
      }

      if (pct >= 95 && chg) {
        qDebug() << "🔌 Full battery triggered";
        emit fullBattery();
      }
    }
  }

  void updateAC() {
    if (!lineIface || !lineIface->isValid())
      return;

    bool online = lineIface->property("Online").toBool();
    if (online != m_acConnected) {
      m_acConnected = online;
      qDebug() << "AC power" << (online ? "connected ✅" : "disconnected ❌");
      emit acChanged();
    }
  }

  QDBusInterface *batteryIface = nullptr;
  QDBusInterface *lineIface = nullptr;
  int m_percentage = -1;
  bool m_charging = false;
  bool m_acConnected = false;
};

int main(int argc, char **argv) {
  QGuiApplication app(argc, argv);

  BatteryDaemon daemon;

  QQmlApplicationEngine engine;
  engine.rootContext()->setContextProperty("Battery", &daemon);
  engine.load(QUrl("qrc:/main.qml"));

  if (engine.rootObjects().isEmpty()) {
    qFatal("❌ Failed to load QML");
  }

  // Get the root QWindow from QML
  QWindow *window = qobject_cast<QWindow *>(engine.rootObjects().first());
  if (!window) {
    qFatal("❌ Root object is not a QWindow");
  }

  // 🧩 Register with LayerShellQt
  auto layerWindow = LayerShellQt::Window::get(window);
  layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);
  layerWindow->setKeyboardInteractivity(
      LayerShellQt::Window::KeyboardInteractivityNone);
  layerWindow->setAnchors({LayerShellQt::Window::AnchorLeft});
  layerWindow->setExclusiveZone(-1);
  layerWindow->setMargins({400, 0, 0, 0});

  window->setFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
  window->setWidth(400);
  window->setHeight(200);

  window->hide();

  return app.exec();
}

#include "main.moc"
