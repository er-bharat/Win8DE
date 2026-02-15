#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QAbstractListModel>
#include <QtDBus/QtDBus>
#include <QProcess>
#include <QDebug>

struct WifiNetwork
{
	QString ssid;
	QString strength;
	QString security;
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
		ConnectedRole
	};
	
	WifiModel(QObject *parent=nullptr) : QAbstractListModel(parent)
	{
		checkWifiState();
		refreshWifi();
	}
	
	// ---------------- MODEL ----------------
	
	int rowCount(const QModelIndex &) const override {
		return networks.size();
	}
	
	QVariant data(const QModelIndex &index, int role) const override
	{
		const auto &n = networks[index.row()];
		
		switch(role)
		{
			case SSIDRole: return n.ssid;
			case StrengthRole: return n.strength;
			case SecurityRole: return n.security;
			case ConnectedRole: return n.connected;
		}
		
		return {};
	}
	
	QHash<int, QByteArray> roleNames() const override
	{
		return {
			{SSIDRole, "ssid"},
			{StrengthRole, "strength"},
			{SecurityRole, "security"},
			{ConnectedRole, "connected"}
		};
	}
	
	// ---------------- WIFI TOGGLE ----------------
	
	bool wifiEnabled() const { return m_wifiEnabled; }
	
	void setWifiEnabled(bool enabled)
	{
		QDBusInterface nm(
			"org.freedesktop.NetworkManager",
			"/org/freedesktop/NetworkManager",
			"org.freedesktop.NetworkManager",
			QDBusConnection::systemBus()
		);
		
		nm.setProperty("WirelessEnabled", enabled);
		
		m_wifiEnabled = enabled;
		emit wifiEnabledChanged();
		
		refreshWifi();
	}
	
	// ---------------- CONNECT / DISCONNECT ----------------
	
	Q_INVOKABLE void toggleConnection(QString ssid, bool currentlyConnected)
	{
		if (currentlyConnected)
		{
			qDebug() << "Disconnecting:" << ssid;
			QProcess::execute("nmcli", {"connection", "down", "id", ssid});
		}
		else
		{
			qDebug() << "Connecting:" << ssid;
			QProcess::execute("nmcli", {"device", "wifi", "connect", ssid});
		}
		
		refreshWifi();
	}
	
	// ---------------- SCAN ----------------
	
	Q_INVOKABLE void refreshWifi()
	{
		beginResetModel();
		networks.clear();
		endResetModel();
		
		QString activeSSID = currentConnection();
		
		QDBusInterface nm(
			"org.freedesktop.NetworkManager",
			"/org/freedesktop/NetworkManager",
			"org.freedesktop.NetworkManager",
			QDBusConnection::systemBus()
		);
		
		QDBusReply<QList<QDBusObjectPath>> devices =
		nm.call("GetDevices");
		
		if (!devices.isValid())
			return;
		
		for (const QDBusObjectPath &path : devices.value())
		{
			QDBusInterface dev(
				"org.freedesktop.NetworkManager",
				path.path(),
							   "org.freedesktop.NetworkManager.Device",
					  QDBusConnection::systemBus()
			);
			
			if (dev.property("DeviceType").toUInt() != 2)
				continue;
			
			QDBusInterface wifi(
				"org.freedesktop.NetworkManager",
				path.path(),
								"org.freedesktop.NetworkManager.Device.Wireless",
					   QDBusConnection::systemBus()
			);
			
			wifi.call("RequestScan", QVariantMap());
			
			QDBusReply<QList<QDBusObjectPath>> aps =
			wifi.call("GetAllAccessPoints");
			
			if (!aps.isValid())
				continue;
			
			beginResetModel();
			
			for (const QDBusObjectPath &apPath : aps.value())
			{
				QDBusInterface ap(
					"org.freedesktop.NetworkManager",
					apPath.path(),
								  "org.freedesktop.NetworkManager.AccessPoint",
					  QDBusConnection::systemBus()
				);
				
				QString ssid =
				QString::fromUtf8(
					ap.property("Ssid").toByteArray()
				);
				
				if (ssid.isEmpty())
					continue;
				
				int strength =
				ap.property("Strength").toUInt();
				
				bool secured =
				ap.property("WpaFlags").toUInt() ||
				ap.property("RsnFlags").toUInt();
				
				networks.append({
					ssid,
					QString::number(strength) + "%",
								secured ? "Secured" : "Open",
								ssid == activeSSID
				});
			}
			
			endResetModel();
		}
	}
	
signals:
	void wifiEnabledChanged();
	
private:
	
	QString currentConnection()
	{
		QProcess proc;
		proc.start("nmcli", {"-t", "-f", "active,ssid", "dev", "wifi"});
		proc.waitForFinished();
		
		QString output = proc.readAllStandardOutput();
		
		for (auto line : output.split("\n"))
		{
			if (line.startsWith("yes:"))
				return line.section(":",1);
		}
		
		return "";
	}
	
	void checkWifiState()
	{
		QDBusInterface nm(
			"org.freedesktop.NetworkManager",
			"/org/freedesktop/NetworkManager",
			"org.freedesktop.NetworkManager",
			QDBusConnection::systemBus()
		);
		
		m_wifiEnabled =
		nm.property("WirelessEnabled").toBool();
	}
	
	QList<WifiNetwork> networks;
	bool m_wifiEnabled = true;
};

// ---------------- MAIN ----------------

int main(int argc, char *argv[])
{
	QGuiApplication app(argc, argv);
	
	WifiModel wifiModel;
	
	QQmlApplicationEngine engine;
	engine.rootContext()->setContextProperty("wifiModel", &wifiModel);
	engine.load(QUrl("qrc:/main.qml"));
	
	if (engine.rootObjects().isEmpty())
		return -1;
	
	return app.exec();
}

#include "main.moc"
