#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QAbstractListModel>
#include <QtDBus/QtDBus>
#include <QProcess>
#include <QDebug>
#include <algorithm>
#include <QtConcurrent>
#include <QTimer>

struct WifiNetwork
{
    QString ssid;
    int strength;          // store raw number as int
    QString security;
    QString band;
    bool connected;
};

class WifiModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool wifiEnabled READ wifiEnabled WRITE setWifiEnabled NOTIFY wifiEnabledChanged)
    
public:
    enum Roles {
        SSIDRole = Qt::UserRole + 1,
        StrengthRole,
        SecurityRole,
        BandRole,
        ConnectedRole
    };
    
    WifiModel(QObject *parent=nullptr) : QAbstractListModel(parent)
    {
        checkWifiState();
    }
    
    int rowCount(const QModelIndex &) const override { return static_cast<int>(networks.size()); }
    
    QVariant data(const QModelIndex &index, int role) const override
    {
        const auto &n = networks[index.row()];
        switch(role) {
            case SSIDRole: return n.ssid;
            case StrengthRole: return QString::number(n.strength) + "%";
            case SecurityRole: return n.security;
            case BandRole: return n.band;
            case ConnectedRole: return n.connected;
        }
        return {};
    }
    
    QHash<int, QByteArray> roleNames() const override {
        return {
            {SSIDRole, "ssid"},
            {StrengthRole, "strength"},
            {SecurityRole, "security"},
            {BandRole, "band"},
            {ConnectedRole, "connected"}
        };
    }
    
    bool wifiEnabled() const { return m_wifiEnabled; }
    
    void setWifiEnabled(bool enabled)
    {
        (void)QtConcurrent::run([this, enabled](){
            QDBusInterface nm(
                "org.freedesktop.NetworkManager",
                "/org/freedesktop/NetworkManager",
                "org.freedesktop.NetworkManager",
                QDBusConnection::systemBus()
            );
            
            nm.setProperty("WirelessEnabled", enabled);
            
            QMetaObject::invokeMethod(this, [this, enabled](){
                m_wifiEnabled = enabled;
                emit wifiEnabledChanged();
                refreshWifi();
            });
        });
    }
    
    Q_INVOKABLE void refreshWifi()
    {
        (void)QtConcurrent::run([this](){
            QList<WifiNetwork> newList;
            QString activeSSID = currentConnection();
            
            QDBusInterface nm(
                "org.freedesktop.NetworkManager",
                "/org/freedesktop/NetworkManager",
                "org.freedesktop.NetworkManager",
                QDBusConnection::systemBus()
            );
            
            QDBusReply<QList<QDBusObjectPath>> devices = nm.call("GetDevices");
            if (!devices.isValid()) return;
            
            for (const auto &path : devices.value())
            {
                QDBusInterface dev(
                    "org.freedesktop.NetworkManager",
                    path.path(),
                                   "org.freedesktop.NetworkManager.Device",
                                   QDBusConnection::systemBus()
                );
                if (dev.property("DeviceType").toUInt() != 2) continue;
                
                QDBusInterface wifi(
                    "org.freedesktop.NetworkManager",
                    path.path(),
                                    "org.freedesktop.NetworkManager.Device.Wireless",
                                    QDBusConnection::systemBus()
                );
                
                wifi.call("RequestScan", QVariantMap());
                QDBusReply<QList<QDBusObjectPath>> aps = wifi.call("GetAllAccessPoints");
                if (!aps.isValid()) continue;
                
                for (const auto &apPath : aps.value())
                {
                    QDBusInterface ap(
                        "org.freedesktop.NetworkManager",
                        apPath.path(),
                                      "org.freedesktop.NetworkManager.AccessPoint",
                                      QDBusConnection::systemBus()
                    );
                    
                    QString ssid = QString::fromUtf8(ap.property("Ssid").toByteArray());
                    if (ssid.isEmpty()) continue;
                    
                    int strength = static_cast<int>(ap.property("Strength").toUInt());
                    uint wpa = ap.property("WpaFlags").toUInt();
                    uint rsn = ap.property("RsnFlags").toUInt();
                    
                    QString security = (!wpa && !rsn) ? "Open" : (rsn ? "WPA2/WPA3" : "WPA");
                    
                    uint freq = ap.property("Frequency").toUInt();
                    QString band = (freq >= 5925) ? "6 GHz" : ((freq >= 5000) ? "5 GHz" : "2.4 GHz");
                    
                    newList.append({ssid, strength, security, band, ssid == activeSSID});
                }
            }
            
            std::sort(newList.begin(), newList.end(),
                      [](const WifiNetwork &a, const WifiNetwork &b){ return a.strength > b.strength; });
            
            QMetaObject::invokeMethod(this, [this, newList=std::move(newList)](){
                beginResetModel();
                networks = newList;
                endResetModel();
            });
        });
    }
    
    Q_INVOKABLE void toggleConnection(QString ssid, bool connected, QString password = "")
    {
        (void)QtConcurrent::run([this, ssid, connected, password](){
            if (connected)
            {
                QProcess::execute("nmcli", {"connection","down","id",ssid});
                QMetaObject::invokeMethod(this, &WifiModel::refreshWifi);
                return;
            }
            
            QStringList args = {"device","wifi","connect",ssid};
            if (!password.isEmpty()) args << "password" << password;
            
            QProcess proc;
            proc.start("nmcli", args);
            proc.waitForFinished();
            
            QString combined = proc.readAllStandardOutput() + proc.readAllStandardError();
            QString lower = combined.toLower();
            
            if (proc.exitCode() == 0)
            {
                QMetaObject::invokeMethod(this, &WifiModel::refreshWifi);
                return;
            }
            
            if (lower.contains("secrets were required") ||
                lower.contains("authentication") ||
                lower.contains("incorrect") ||
                lower.contains("wrong password"))
            {
                QProcess::execute("nmcli", {"connection","delete","id",ssid});
                QMetaObject::invokeMethod(this, [this, ssid](){
                    emit passwordRequired(ssid);
                });
                return;
            }
        });
    }
    
signals:
    void wifiEnabledChanged();
    void passwordRequired(QString ssid);
    
private:
    QList<WifiNetwork> networks;
    bool m_wifiEnabled = true;
    
    QString currentConnection()
    {
        QProcess proc;
        proc.start("nmcli", {"-t","-f","active,ssid","dev","wifi"});
        proc.waitForFinished();
        QString output = QString::fromUtf8(proc.readAllStandardOutput());
        for (const QString &line : output.split('\n', Qt::SkipEmptyParts))
        {
            QStringList parts = line.split(':');
            if (parts.size() >= 2 && parts[0] == "yes") return parts[1];
        }
        return {};
    }
    
    void checkWifiState()
    {
        QDBusInterface nm(
            "org.freedesktop.NetworkManager",
            "/org/freedesktop/NetworkManager",
            "org.freedesktop.NetworkManager",
            QDBusConnection::systemBus()
        );
        m_wifiEnabled = nm.property("WirelessEnabled").toBool();
    }
};

// ---------------- MAIN ----------------

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    QQmlApplicationEngine engine;
    engine.load(QUrl("qrc:/main.qml"));
    if (engine.rootObjects().isEmpty())
        return -1;
    
    WifiModel *wifiModel = new WifiModel();
    engine.rootContext()->setContextProperty("wifiModel", wifiModel);
    
    QTimer::singleShot(0, wifiModel, &WifiModel::refreshWifi);
    
    return app.exec();
}

#include "main.moc"
