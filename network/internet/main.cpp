#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QAbstractListModel>
#include <QtDBus/QtDBus>
#include <QProcess>
#include <QDebug>
#include <algorithm>

struct WifiNetwork
{
	QString ssid;
	int strength;          // store raw number
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
			case StrengthRole: return QString::number(n.strength) + "%";
			case SecurityRole: return n.security;
			case BandRole: return n.band;
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
			{BandRole, "band"},
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
	
	// ---------------- CONNECT ----------------
	
	Q_INVOKABLE void toggleConnection(QString ssid, bool connected)
	{
		if (connected)
			QProcess::execute("nmcli", {"connection","down","id",ssid});
		else
			QProcess::execute("nmcli", {"device","wifi","connect",ssid});
		
		refreshWifi();
	}
	
	// ---------------- SCAN ----------------
	
	Q_INVOKABLE void refreshWifi()
	{
		QList<WifiNetwork> newList;
		
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
		
		for (const auto &path : devices.value())
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
			
			for (const auto &apPath : aps.value())
			{
				QDBusInterface ap(
					"org.freedesktop.NetworkManager",
					apPath.path(),
								  "org.freedesktop.NetworkManager.AccessPoint",
					  QDBusConnection::systemBus()
				);
				
				QString ssid =
				QString::fromUtf8(ap.property("Ssid").toByteArray());
				
				if (ssid.isEmpty())
					continue;
				
				int strength =
				ap.property("Strength").toUInt();
				
				// -------- REAL SECURITY DETECTION --------
				
				uint wpa = ap.property("WpaFlags").toUInt();
				uint rsn = ap.property("RsnFlags").toUInt();
				
				QString security;
				
				if (!wpa && !rsn)
					security = "Open";
				else if (rsn)
					security = "WPA2/WPA3";
				else
					security = "WPA";
				
				// -------- GHz detection --------
				
				uint freq = ap.property("Frequency").toUInt();
				
				QString band;
				
				if (freq >= 5925)
					band = "6 GHz";
				else if (freq >= 5000)
					band = "5 GHz";
				else
					band = "2.4 GHz";
				
				newList.append({
					ssid,
					strength,
					security,
					band,
					ssid == activeSSID
				});
			}
		}
		
		// ⭐ strongest first
		std::sort(newList.begin(), newList.end(),
				  [](const WifiNetwork &a, const WifiNetwork &b){
					  return a.strength > b.strength;
				  });
		
		beginResetModel();
		networks = std::move(newList);
		endResetModel();
	}
	
signals:
	void wifiEnabledChanged();
	
private:
	
	QString currentConnection()
	{
		QProcess proc;
		proc.start("nmcli", {"-t","-f","active,ssid","dev","wifi"});
		proc.waitForFinished();
		
		QString output =
		QString::fromUtf8(proc.readAllStandardOutput());
		
		for (const QString &line :
			output.split('\n', Qt::SkipEmptyParts))
		{
			QStringList parts = line.split(':');
			
			if (parts.size() >= 2 && parts[0] == "yes")
				return parts[1];
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
