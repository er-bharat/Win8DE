#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDBusObjectPath>
#include <QDebug>
#include <QProcess>

class BatteryDaemon : public QObject {
  Q_OBJECT
  
public:
  BatteryDaemon(QObject *parent = nullptr) : QObject(parent) {
    qDebug() << "🔋 BatteryDaemon started";
    
    detectDevices();
    
    if (batteryIface) {
      QDBusConnection::systemBus().connect(
        "org.freedesktop.UPower", batteryIface->path(),
                                           "org.freedesktop.DBus.Properties", "PropertiesChanged",
                                           this, SLOT(onBatteryChanged(QString, QVariantMap, QStringList)));
      
      updateBattery();
    }
    
    if (lineIface) {
      QDBusConnection::systemBus().connect(
        "org.freedesktop.UPower", lineIface->path(),
                                           "org.freedesktop.DBus.Properties", "PropertiesChanged",
                                           this, SLOT(onACChanged(QString, QVariantMap, QStringList)));
      
      updateAC();
    }
  }
  
private slots:
  void onBatteryChanged(const QString &, const QVariantMap &changed,
                        const QStringList &) {
    if (changed.contains("Percentage") || changed.contains("State"))
      updateBattery();
                        }
                        
                        void onACChanged(const QString &, const QVariantMap &changed,
                                         const QStringList &) {
                          if (changed.contains("Online"))
                            updateAC();
                                         }
                                         
private:
  // 🔥 Launch client
  void triggerEvent(const QString &event) {
    qDebug() << "🚀 Trigger:" << event;
    QProcess::startDetached("battery-client", QStringList() << event);
  }
  
  void detectDevices() {
    QDBusInterface upower("org.freedesktop.UPower",
                          "/org/freedesktop/UPower",
                          "org.freedesktop.UPower",
                          QDBusConnection::systemBus());
    
    if (!upower.isValid()) {
      qWarning() << "❌ UPower interface invalid";
      return;
    }
    
    QDBusReply<QList<QDBusObjectPath>> reply =
    upower.call("EnumerateDevices");
    
    if (!reply.isValid()) {
      qWarning() << "❌ EnumerateDevices failed";
      return;
    }
    
    const QList<QDBusObjectPath> devices = reply.value();
    
    for (const QDBusObjectPath &path : devices) {
      QDBusInterface dev("org.freedesktop.UPower", path.path(),
                         "org.freedesktop.UPower.Device",
                         QDBusConnection::systemBus());
      
      if (!dev.isValid())
        continue;
      
      int type = dev.property("Type").toInt();
      bool present = dev.property("IsPresent").toBool();
      
      // 🔋 Battery
      if (type == 2 && present && !batteryIface) {
        batteryIface = new QDBusInterface(
          "org.freedesktop.UPower", path.path(),
                                          "org.freedesktop.UPower.Device",
                                          QDBusConnection::systemBus(), this);
        
        qDebug() << "✅ Battery found at" << path.path();
      }
      
      // 🔌 AC
      if (type == 1 && !lineIface) {
        lineIface = new QDBusInterface(
          "org.freedesktop.UPower", path.path(),
                                       "org.freedesktop.UPower.Device",
                                       QDBusConnection::systemBus(), this);
        
        qDebug() << "🔌 AC adapter found at" << path.path();
      }
    }
  }
  
  void updateBattery() {
    if (!batteryIface)
      return;
    
    int pct = batteryIface->property("Percentage").toInt();
    int state = batteryIface->property("State").toInt();
    
    bool isCharging = (state == 1);
    bool isDischarging = (state == 2);
    
    if (pct != m_percentage || isCharging != m_charging) {
      m_percentage = pct;
      m_charging = isCharging;
      
      qDebug() << "Battery:" << pct << "%";
      
      // ⚡ Charging
      if (isCharging && !m_lastChargingState) {
        triggerEvent("charging");
      }
      
      // 🔋 Discharging
      if (isDischarging && m_lastChargingState) {
        triggerEvent("discharging");
      }
      
      // ⚠ Low battery (only once)
      if (pct <= 20 && !isCharging && !lowTriggered) {
        triggerEvent("low");
        lowTriggered = true;
      }
      if (pct > 25) {
        lowTriggered = false;
      }
      
      // 🔌 Full battery (only once)
      if (pct >= 95 && isCharging && !fullTriggered) {
        triggerEvent("full");
        fullTriggered = true;
      }
      if (pct < 90) {
        fullTriggered = false;
      }
      
      m_lastChargingState = isCharging;
    }
  }
  
  void updateAC() {
    if (!lineIface)
      return;
    
    bool online = lineIface->property("Online").toBool();
    
    if (online != m_acConnected) {
      m_acConnected = online;
      
      if (online) {
        qDebug() << "🔌 AC plugged";
        triggerEvent("plugged");
      } else {
        qDebug() << "❌ AC unplugged";
        triggerEvent("unplugged");
      }
    }
  }
  
  // Interfaces
  QDBusInterface *batteryIface = nullptr;
  QDBusInterface *lineIface = nullptr;
  
  // State
  int m_percentage = -1;
  bool m_charging = false;
  bool m_acConnected = false;
  
  // Guards (prevent spam)
  bool lowTriggered = false;
  bool fullTriggered = false;
  bool m_lastChargingState = false;
};

int main(int argc, char **argv) {
  QCoreApplication app(argc, argv);
  
  BatteryDaemon daemon;
  
  return app.exec();
}

#include "daemon.moc"
