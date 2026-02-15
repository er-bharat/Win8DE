#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QAbstractListModel>
#include <QProcess>
#include <QDebug>
#include <QTimer>
#include <algorithm>

struct BluetoothDevice
{
	QString name;
	QString address;
	bool paired;
	bool connected;
};

class BluetoothModel : public QAbstractListModel
{
	Q_OBJECT
	Q_PROPERTY(bool bluetoothEnabled READ bluetoothEnabled WRITE setBluetoothEnabled NOTIFY bluetoothEnabledChanged)
	
public:
	enum Roles {
		NameRole = Qt::UserRole + 1,
		AddressRole,
		PairedRole,
		ConnectedRole
	};
	
	BluetoothModel(QObject *parent = nullptr) : QAbstractListModel(parent)
	{
		checkBluetoothState();
	}
	
	int rowCount(const QModelIndex &) const override {
		return devices.size();
	}
	
	QVariant data(const QModelIndex &index, int role) const override {
		const auto &d = devices[index.row()];
		switch (role) {
			case NameRole: return d.name;
			case AddressRole: return d.address;
			case PairedRole: return d.paired;
			case ConnectedRole: return d.connected;
		}
		return {};
	}
	
	QHash<int, QByteArray> roleNames() const override {
		return {
			{NameRole, "name"},
			{AddressRole, "address"},
			{PairedRole, "paired"},
			{ConnectedRole, "connected"}
		};
	}
	
	// ---------------- BLUETOOTH TOGGLE ----------------
	bool bluetoothEnabled() const { return m_bluetoothEnabled; }
	
	Q_INVOKABLE void setBluetoothEnabled(bool enabled)
	{
		if (enabled) {
			QProcess::execute("rfkill", {"unblock", "bluetooth"});
		} else {
			QProcess::execute("rfkill", {"block", "bluetooth"});
		}
		m_bluetoothEnabled = enabled;
		emit bluetoothEnabledChanged();
		
		// Refresh device list after toggling
		QTimer::singleShot(500, this, &BluetoothModel::refreshDevices);
	}
	
	// ---------------- SCAN ----------------
	Q_INVOKABLE void refreshDevices() {
		beginResetModel();
		devices.clear();
		
		if (!m_bluetoothEnabled) {
			endResetModel();
			return;
		}
		
		QProcess proc;
		proc.start("bluetoothctl", {"devices"});
		proc.waitForFinished();
		
		QString output = proc.readAllStandardOutput();
		for (const QString &line : output.split('\n', Qt::SkipEmptyParts)) {
			if (!line.startsWith("Device"))
				continue;
			QStringList parts = line.split(' ', Qt::SkipEmptyParts);
			if (parts.size() < 3) continue;
			
			QString addr = parts[1];
			QString name = parts.mid(2).join(" ");
			
			devices.append({name, addr, isPaired(addr), isConnected(addr)});
		}
		
		endResetModel();
	}
	
	// ---------------- PAIR & CONNECT ----------------
	Q_INVOKABLE void toggleConnection(QString address, bool connected) {
		if (!m_bluetoothEnabled)
			return;
		
		if (connected) {
			QProcess::execute("bluetoothctl", {"disconnect", address});
		} else {
			if (!isPaired(address)) {
				QProcess pairProc;
				pairProc.start("bluetoothctl", {"pair", address});
				pairProc.waitForFinished();
				QString out = pairProc.readAllStandardOutput();
				if (!out.contains("Pairing successful")) {
					emit pairingRequired(address);
					return;
				}
			}
			
			QProcess connectProc;
			connectProc.start("bluetoothctl", {"connect", address});
			connectProc.waitForFinished();
			QString out = connectProc.readAllStandardOutput();
			if (!out.contains("Connection successful")) {
				emit connectionFailed(address);
			}
		}
		
		refreshDevices();
	}
	
signals:
	void pairingRequired(QString address);
	void connectionFailed(QString address);
	void bluetoothEnabledChanged();
	
private:
	bool isPaired(const QString &address) {
		QProcess proc;
		proc.start("bluetoothctl", {"info", address});
		proc.waitForFinished();
		return proc.readAllStandardOutput().contains("Paired: yes");
	}
	
	bool isConnected(const QString &address) {
		QProcess proc;
		proc.start("bluetoothctl", {"info", address});
		proc.waitForFinished();
		return proc.readAllStandardOutput().contains("Connected: yes");
	}
	
	void checkBluetoothState() {
		QProcess proc;
		proc.start("rfkill", {"list", "bluetooth"});
		proc.waitForFinished();
		QString out = proc.readAllStandardOutput();
		m_bluetoothEnabled = !out.contains("Soft blocked: yes");
	}
	
	QList<BluetoothDevice> devices;
	bool m_bluetoothEnabled = true;
};


// ---------------- MAIN ----------------

int main(int argc, char *argv[])
{
	QGuiApplication app(argc, argv);
	
	QQmlApplicationEngine engine;
	
	engine.load(QUrl("qrc:/main.qml"));
	if (engine.rootObjects().isEmpty())
		return -1;
	
	BluetoothModel *btModel = new BluetoothModel();
	engine.rootContext()->setContextProperty("btModel", btModel);
	
	// Refresh devices after UI is loaded
	QTimer::singleShot(0, btModel, &BluetoothModel::refreshDevices);
	
	return app.exec();
}

#include "main.moc"
