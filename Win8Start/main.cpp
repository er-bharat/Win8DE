// main.cpp
#include <QGuiApplication>
#include <QLockFile>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QObject>
#include <QList>
#include <QString>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QStandardPaths>
#include <QProcess>
#include <QAbstractListModel>
#include <QMimeData>
#include <QDrag>
#include <QPixmap>
#include <QQuickItem>
#include <QQuickWindow>
#include <LayerShellQt/window.h>
#include <QImage>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QCryptographicHash>

#include <QLocalServer>
#include <QLocalSocket>

#include <QDebug>
#include <QTimer>
#include <algorithm>
#include <pwd.h>
#include <unistd.h>

#include <QtConcurrent>
#include <QFutureWatcher>
#include <functional>

// ----------------------------
// Simple Async helper
// ----------------------------
class Async : public QObject {
    Q_OBJECT
public:
    explicit Async(QObject* parent = nullptr) : QObject(parent) {}

    template<typename Func, typename Callback>
    void run(Func func, Callback callback) {
        using R = decltype(func());
        QFuture<R> future = QtConcurrent::run(func);
        QFutureWatcher<R>* watcher = new QFutureWatcher<R>(this);

        // Capture the future by value and callback by value (copy)
        connect(watcher, &QFutureWatcher<R>::finished, this, [watcher, future, callback]() mutable {
            try {
                R result = future.result();
                callback(result);
            } catch (...) {
                // swallow exceptions to avoid crashing; callback may not be called
            }
            watcher->deleteLater();
        });

        watcher->setFuture(future);
    }
};

// ----------------------------
// AppInfo struct
// ----------------------------
struct AppInfo {
    QString name;
    QString command;
    QString icon;
    QString desktopFilePath;
};

// ----------------------------
// AppModel class
// ----------------------------
class AppModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        CommandRole,
        IconRole,
        LetterRole,
        HeaderVisibleRole,
        DesktopFileRole
    };

    AppModel(QObject* parent = nullptr) : QAbstractListModel(parent) {}

    void setApps(const QList<AppInfo>& apps) {
        beginResetModel();
        m_allApps = apps;  // store full list
        m_apps = apps;     // visible list
        endResetModel();
    }


    int rowCount(const QModelIndex &parent = QModelIndex()) const override {
        Q_UNUSED(parent);
        return m_apps.count();
    }

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override {
        if(!index.isValid() || index.row() < 0 || index.row() >= m_apps.count())
            return QVariant();

        const AppInfo &app = m_apps[index.row()];
        switch(role) {
            case NameRole: return app.name;
            case CommandRole: return app.command;
            case IconRole: return app.icon;
            case LetterRole: return app.name.left(1).toUpper();
            case HeaderVisibleRole:
                if(index.row() == 0) return true;
                return app.name.left(1).toUpper() != m_apps[index.row()-1].name.left(1).toUpper();
            case DesktopFileRole: return app.desktopFilePath;
            default: return QVariant();
        }
    }

    QHash<int, QByteArray> roleNames() const override {
        return {
            {NameRole, "name"},
            {CommandRole, "command"},
            {IconRole, "icon"},
            {LetterRole, "letter"},
            {HeaderVisibleRole, "headerVisible"},
            {DesktopFileRole, "desktopFilePath"}
        };
    }

    Q_INVOKABLE void search(const QString &query) {
        QString q = query.trimmed().toLower();

        beginResetModel();

        if (q.isEmpty()) {
            // restore full list
            m_apps = m_allApps;
        } else {
            m_apps.clear();
            for (const auto &app : m_allApps) {
                if (app.name.toLower().contains(q)) {
                    m_apps.append(app);
                }
            }
        }

        endResetModel();
    }

private:
    QList<AppInfo> m_apps;
    QList<AppInfo> m_allApps;
};

// ----------------------------
// AppLauncher class (FULL VERSION WITH CACHING + ASYNC)
// ----------------------------
class AppLauncher : public QObject
{
    Q_OBJECT
public:
    explicit AppLauncher(QObject* parent = nullptr) : QObject(parent) {}

    // ------------------------------------
    // Get current user
    // ------------------------------------
    Q_INVOKABLE QString getCurrentUser() const {
        QString user = qEnvironmentVariable("USER");

        if (user.isEmpty())
            user = qEnvironmentVariable("USERNAME");

        if (user.isEmpty()) {
            struct passwd *pw = getpwuid(getuid());
            if (pw)
                user = QString::fromUtf8(pw->pw_name);
        }

        if (user.isEmpty())
            user = "unknown";

        return user;
    }

    // ------------------------------------
    // Async wrapper
    // ------------------------------------
    Q_INVOKABLE void listApplicationsAsync() {
        m_async.run([this]() -> QVariantList {
            return listApplicationsSync();
        }, [this](QVariantList apps) {
            emit applicationsLoaded(apps);
        });
    }

    // ------------------------------------
    // SYNC implementation with caching
    // ------------------------------------
    QVariantList listApplicationsSync() {
        QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
        QDir().mkpath(configDir);

        QString cacheFile = configDir + "/apps_cache_v1.json";
        QString hashFile  = configDir + "/apps_cache_hash_v1.txt";

        // Compute current hash
        QByteArray currentHash = computeAppsHash();

        // Load saved hash
        QByteArray savedHash;
        {
            QFile hf(hashFile);
            if (hf.open(QIODevice::ReadOnly)) {
                savedHash = hf.readAll().trimmed();
                hf.close();
            }
        }

        // If hashes match → use cache
        if (savedHash == currentHash && QFile::exists(cacheFile)) {
            QFile f(cacheFile);
            if (f.open(QIODevice::ReadOnly)) {
                QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
                f.close();

                if (doc.isArray()) {
                    qDebug() << "⚡ Loaded applications from cache.";
                    return doc.array().toVariantList();
                }
            }
        }

        // Rescan .desktop files
        qDebug() << "🔍 Scanning application directories...";

        QVariantList appList;
        QStringList dirs = {
            "/usr/share/applications",
            QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation)
        };

        for (const QString &dirPath : dirs) {
            QDir dir(dirPath);
            if (!dir.exists()) continue;

            QStringList files = dir.entryList(QStringList() << "*.desktop", QDir::Files);

            for (const QString &file : files) {
                QString path = dir.absoluteFilePath(file);
                QFile f(path);

                if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
                    continue;

                QString name, exec, iconName;
                bool noDisplay = false;
                bool inMainSection = false;

                while (!f.atEnd()) {
                    QString line = f.readLine().trimmed();

                    if (line.startsWith('[')) {
                        if (line == "[Desktop Entry]") inMainSection = true;
                        else if (line.startsWith("[Desktop Action")) break;
                        else inMainSection = false;
                        continue;
                    }

                    if (!inMainSection) continue;

                    if (line.startsWith("Name="))
                        name = line.mid(5).trimmed();

                    else if (line.startsWith("Exec=")) {
                        exec = line.mid(5).trimmed();
                        exec.replace(QRegularExpression("%[UuFfDdNnVvMm]"), "");
                    }

                    else if (line.startsWith("Icon="))
                        iconName = line.mid(5).trimmed();

                    else if (line.startsWith("NoDisplay=") &&
                        line.mid(10).trimmed().toLower() == "true")
                        noDisplay = true;
                }

                f.close();

                if (name.isEmpty() || exec.isEmpty() || noDisplay)
                    continue;

                QVariantMap app;
                app["name"] = name;
                app["command"] = exec;
                app["icon"] = resolveIcon(iconName);
                app["desktopFilePath"] = path;

                appList.append(app);
            }
        }

        // Sort apps alphabetically
        std::sort(appList.begin(), appList.end(), [](const QVariant &a, const QVariant &b) {
            return a.toMap()["name"].toString().toLower() <
            b.toMap()["name"].toString().toLower();
        });

        // Save cache
        {
            QFile f(cacheFile);
            if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
                QJsonArray arr;
                for (const QVariant &v : appList)
                    arr.append(QJsonObject::fromVariantMap(v.toMap()));

                f.write(QJsonDocument(arr).toJson());
                f.close();
            }
        }

        // Save hash
        {
            QFile hf(hashFile);
            if (hf.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
                hf.write(currentHash);
                hf.close();
            }
        }

        qDebug() << "✅ Applications scanned and cached.";
        return appList;
    }

    // ------------------------------------
    // Icon resolver
    // ------------------------------------
    Q_INVOKABLE QString resolveIcon(const QString& name) const {
        if (name.isEmpty())
            return "qrc:/placeholder.svg";

        if (QFile::exists(name))
            return "file://" + name;

        QString home = QDir::homePath();
        const QStringList iconDirs = {
            "/usr/share/icons/hicolor/scalable/apps/",
            "/usr/share/icons/hicolor/256x256/apps/",
            "/usr/share/icons/hicolor/128x128/apps/",
            "/usr/share/icons/hicolor/64x64/apps/",
            "/usr/share/icons/hicolor/48x48/apps/",
            "/usr/share/pixmaps/",
            "/usr/share/icons/breeze/apps/64/",
            "/usr/share/icons/breeze/apps/48/",
            "/usr/share/icons/breeze/apps/32/",
            home + "/.local/share/icons/hicolor/256x256/apps/"
        };

        for (const QString& dir : iconDirs) {
            QString pngPath = dir + name + ".png";
            QString svgPath = dir + name + ".svg";
            if (QFile::exists(pngPath)) return "file://" + pngPath;
                if (QFile::exists(svgPath)) return "file://" + svgPath;
        }

        return "qrc:/placeholder.svg";
    }

    // ------------------------------------
    // Launch application
    // ------------------------------------
    Q_INVOKABLE void launchApp(const QString &command) {
        if (command.isEmpty()) {
            qWarning() << "⚠️ launchApp: Empty command.";
            return;
        }

        QString cmd = command.trimmed();
        cmd.replace(QRegularExpression("%[uUfFdDnNvVmM]"), "");

        // Expand env vars
        QRegularExpression envVarPattern(R"(\$(\w+)|\$\{([^}]+)\})");
        QRegularExpressionMatchIterator it = envVarPattern.globalMatch(cmd);
        while (it.hasNext()) {
            auto match = it.next();
            QString var = match.captured(1).isEmpty()
                ? match.captured(2)
                : match.captured(1);
            QString val = QString::fromUtf8(qgetenv(var.toUtf8()));
            if (!val.isEmpty())
                cmd.replace(match.captured(0), val);
        }

        QStringList parts = QProcess::splitCommand(cmd);
        if (parts.isEmpty()) return;

        QString program = parts.takeFirst();
        QString programPath = QFile::exists(program)
            ? program
            : QStandardPaths::findExecutable(program);

        if (programPath.isEmpty()) {
            qWarning() << "❌ launchApp: Executable not found:" << program;
            return;
        }

        QProcess::startDetached(programPath, parts);
}

// ------------------------------------
// Drag to desktop
// ------------------------------------
Q_INVOKABLE void startSystemDrag(const QString &desktopFilePath, QQuickItem *iconItem)
{
    if (!iconItem || !iconItem->window())
        return;

    QFileInfo fi(desktopFilePath);
    if (!fi.exists()) {
        qWarning() << "Desktop file not found:" << desktopFilePath;
        return;
    }

    QMimeData *mimeData = new QMimeData;
    mimeData->setUrls({ QUrl::fromLocalFile(desktopFilePath) });

    QByteArray specialData("copy\n" +
    QUrl::fromLocalFile(desktopFilePath).toEncoded() +
    "\n");
    mimeData->setData("x-special/gnome-copied-files", specialData);

    QDrag *drag = new QDrag(iconItem->window());
    drag->setMimeData(mimeData);

    QQuickWindow *win = iconItem->window();
    if (win) {
        QImage rendered = win->grabWindow();
        if (!rendered.isNull()) {
            QPoint itemPos = iconItem->mapToScene(QPointF(0, 0)).toPoint();
            QRect rect(itemPos, QSize(iconItem->width(), iconItem->height()));
            QPixmap pix = QPixmap::fromImage(rendered.copy(rect));
            drag->setPixmap(pix);
            drag->setHotSpot(QPoint(pix.width()/2, pix.height()/2));
        }
    }

    drag->exec(Qt::CopyAction);
}

signals:
    void applicationsLoaded(const QVariantList &apps);

    private:
        Async m_async;

        // ------------------------------------
        // Directory hash for caching
        // ------------------------------------
        QByteArray computeAppsHash() const {
            QCryptographicHash md5(QCryptographicHash::Md5);

            QStringList dirs = {
                "/usr/share/applications",
                QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation)
            };

            for (const QString &dir : dirs) {
                QDir d(dir);
                if (!d.exists()) continue;

                QFileInfoList list = d.entryInfoList(QDir::Files | QDir::NoDotAndDotDot);
                for (const QFileInfo &fi : list) {
                    md5.addData(fi.fileName().toUtf8());
                    md5.addData(QByteArray::number(fi.lastModified().toSecsSinceEpoch()));
                }
            }

            return md5.result().toHex();
        }
        };

class Launcher : public QObject {
    Q_OBJECT
public:
    explicit Launcher(QObject *parent = nullptr) : QObject(parent) {}

    // QML: Launcher.launch("Win8Settings")
    Q_INVOKABLE void launch(const QString &target) {
        if (target.isEmpty())
            return;

        // 1️⃣ If it's a desktop file name or id
        if (target.endsWith(".desktop") || !target.contains('/')) {
            QString desktop = findDesktopFile(target);
            if (!desktop.isEmpty()) {
                launchDesktopFile(desktop);
                return;
            }
        }

        // 2️⃣ Otherwise treat it as a command
        launchCommand(target);
    }

private:
    void launchCommand(const QString &cmd) {
        QString cleaned = cmd;
        cleaned.replace(QRegularExpression("%[uUfFdDnNvVmM]"), "");

        QStringList parts = QProcess::splitCommand(cleaned);
        if (parts.isEmpty())
            return;

        QString program = parts.takeFirst();
        QString execPath = QFile::exists(program)
        ? program
        : QStandardPaths::findExecutable(program);

        if (execPath.isEmpty()) {
            qWarning() << "Launcher: executable not found:" << program;
            return;
        }

        QProcess::startDetached(execPath, parts);
    }

    void launchDesktopFile(const QString &path) {
        QFile f(path);
        if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
            return;

        QString exec;
        bool inMain = false;

        while (!f.atEnd()) {
            QString line = f.readLine().trimmed();

            if (line == "[Desktop Entry]") {
                inMain = true;
                continue;
            }
            if (line.startsWith('['))
                inMain = false;

            if (inMain && line.startsWith("Exec=")) {
                exec = line.mid(5).trimmed();
                exec.replace(QRegularExpression("%[uUfFdDnNvVmM]"), "");
                break;
            }
        }
        f.close();

        if (!exec.isEmpty())
            launchCommand(exec);
    }

    QString findDesktopFile(const QString &name) const {
        QString desktopName = name.endsWith(".desktop")
        ? name
        : name + ".desktop";

        QStringList dirs = {
            "/usr/share/applications",
            QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation)
        };

        for (const QString &dir : dirs) {
            QString path = dir + "/" + desktopName;
            if (QFile::exists(path))
                return path;
        }
        return QString();
    }
};



// ----------------------------
// Tile Model (JSON persistent) - Async-enabled
// ----------------------------
struct Tile {
    QString name;
    QString icon;
    QString desktopFile;
    QString command;
    double x;
    double y;
    QString size;
};

Q_DECLARE_METATYPE(Tile)

class TileModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles { NameRole = Qt::UserRole + 1, IconRole, DesktopFileRole, CommandRole, XRole, YRole, SizeRole };

    TileModel(QObject *parent = nullptr) : QAbstractListModel(parent) {
        // Load asynchronously on construction
        loadAsync();
    }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override {
        Q_UNUSED(parent);
        return m_tiles.count();
    }

    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= m_tiles.count())
            return QVariant();
        const Tile &t = m_tiles[index.row()];
        switch (role) {
            case NameRole: return t.name;
            case IconRole: return t.icon;
            case DesktopFileRole: return t.desktopFile;
            case CommandRole: return t.command;
            case XRole: return t.x;
            case YRole: return t.y;
            case SizeRole: return t.size;
            default: return QVariant();
        }
    }

    QHash<int, QByteArray> roleNames() const override {
        return {{NameRole, "name"}, {IconRole, "icon"}, {DesktopFileRole, "desktopFile"}, {CommandRole, "command"},
        {XRole, "x"}, {YRole, "y"}, {SizeRole, "size"}};
    }

    // ---------- Async add tile ----------
    Q_INVOKABLE void addTileFromDesktopFile(const QString &filePath, double dropX, double dropY) {
        // parse on background thread
        m_async.run([=]() -> Tile {
            Tile t;
            QFile f(filePath);
            if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
                t.name = QFileInfo(filePath).baseName();
                t.icon.clear();
                t.desktopFile = filePath;
                t.command.clear();
                t.x = dropX;
                t.y = dropY;
                t.size = "medium";
                return t;
            }

            QString name, icon, command;
            bool inMainSection = false;

            while (!f.atEnd()) {
                QString line = f.readLine().trimmed();

                if (line.startsWith('[')) {
                    // Only process the main [Desktop Entry] section
                    if (line == "[Desktop Entry]") {
                        inMainSection = true;
                        continue;
                    } else if (line.startsWith("[Desktop Action")) {
                        // Stop reading once subactions begin
                        break;
                    } else {
                        inMainSection = false;
                        continue;
                    }
                }

                if (!inMainSection)
                    continue;

                if (line.startsWith("Name="))
                    name = line.mid(5).trimmed();
                else if (line.startsWith("Icon="))
                    icon = line.mid(5).trimmed();
                else if (line.startsWith("Exec=")) {
                    command = line.mid(5).trimmed();
                    // Remove placeholders like %U, %F, %u etc.
                    command.replace(QRegularExpression("%[UuFfDdNnVvMm]"), "");
                }
            }

            f.close();

            if (name.isEmpty())
                name = QFileInfo(filePath).baseName();

            Tile ret;
            ret.name = name;
            ret.icon = icon;
            ret.desktopFile = filePath;
            ret.command = command;
            ret.x = dropX;
            ret.y = dropY;
            ret.size = "medium";
            return ret;
        }, [=](Tile t) {
            // back on main thread: insert tile and persist
            beginInsertRows(QModelIndex(), m_tiles.count(), m_tiles.count());
            m_tiles.append(t);
            endInsertRows();
            saveAsync();
            qDebug() << "✅ Added tile (async):" << t.name << "→" << t.command;
        });
    }

    Q_INVOKABLE void updateTilePosition(int index, double x, double y) {
        if (index < 0 || index >= m_tiles.count()) return;
        m_tiles[index].x = x;
        m_tiles[index].y = y;
        emit dataChanged(this->index(index), this->index(index), {XRole, YRole});
        saveAsync();
    }

    Q_INVOKABLE void resizeTile(int index, const QString &size) {
        if (index < 0 || index >= m_tiles.count()) return;
        m_tiles[index].size = size;
        emit dataChanged(this->index(index), this->index(index), {SizeRole});
        saveAsync();
    }

    Q_INVOKABLE void removeTile(int index) {
        if (index < 0 || index >= m_tiles.count()) return;
        beginRemoveRows(QModelIndex(), index, index);
        m_tiles.removeAt(index);
        endRemoveRows();
        saveAsync();
    }

    // ---------- Async load/save ----------
    void loadAsync() {
        m_async.run([=]() -> QList<Tile> {
            QList<Tile> tiles;
            QFile file(jsonPath());
            if (!file.exists()) return tiles;
            if (!file.open(QIODevice::ReadOnly)) return tiles;
            QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
            file.close();
            QJsonArray arr = doc.array();
            for (auto v : arr) {
                QJsonObject o = v.toObject();
                Tile t;
                t.name = o["name"].toString();
                t.icon = o["icon"].toString();
                t.desktopFile = o["desktopFile"].toString();
                t.command = o["command"].toString();
                t.x = o["x"].toDouble();
                t.y = o["y"].toDouble();
                t.size = o["size"].toString("medium");
                tiles.append(t);
            }
            return tiles;
        }, [this](QList<Tile> tiles) {
            beginResetModel();
            m_tiles = tiles;
            endResetModel();
            qDebug() << "✅ TileModel loaded (async):" << m_tiles.size();
        });
    }

    void saveAsync() const {
        // copy for thread-safety
        QList<Tile> tiles = m_tiles;

        // Use a new Async object so we don't tie to constness of this
        Async* localAsync = new Async(const_cast<TileModel*>(this));
        localAsync->run([=]() -> bool {
            QJsonArray arr;
            for (const auto &t : tiles) {
                QJsonObject o;
                o["name"] = t.name;
                o["icon"] = t.icon;
                o["desktopFile"] = t.desktopFile;
                o["command"] = t.command;
                o["x"] = t.x;
                o["y"] = t.y;
                o["size"] = t.size;
                arr.append(o);
            }
            QFile file(jsonPath());
            QDir().mkpath(QFileInfo(file).absolutePath());
            if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
                file.write(QJsonDocument(arr).toJson(QJsonDocument::Indented));
                file.close();
                return true;
            }
            return false;
        }, [=](bool ok) {
            Q_UNUSED(ok);
            // delete will be handled by parent (we set parent in constructor)
        });
    }

private:
    QList<Tile> m_tiles;
    Async m_async;

    QString jsonPath() const {
        return QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation)
        + "/launcher_tiles8_1.json";
    }
};

// ----------------------------
// PowerControl (unchanged)
// ----------------------------
class PowerControl : public QObject {
    Q_OBJECT
public:
    explicit PowerControl(QObject* parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void shutdown() { QProcess::startDetached("systemctl", {"poweroff"}); }
    Q_INVOKABLE void reboot()   { QProcess::startDetached("systemctl", {"reboot"}); }
    Q_INVOKABLE void suspend()  { QProcess::startDetached("systemctl", {"suspend"}); }
    Q_INVOKABLE void logout() {
        QProcess::startDetached("bash", {"-c", "swaymsg exit || niri msg action quit || hyprctl dispatch exit || labwc -e || loginctl terminate-user $USER"});
        QCoreApplication::quit(); // optional: quit launcher immediately
    }

};

// ----------------------------
// Battery (unchanged)
// ----------------------------
class Battery : public QObject {
    Q_OBJECT
    Q_PROPERTY(int percent READ percent NOTIFY percentChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool present READ present NOTIFY presentChanged)
    Q_PROPERTY(bool charging READ charging NOTIFY chargingChanged)

public:
    explicit Battery(QObject* parent = nullptr)
    : QObject(parent),
    m_percent(-1),
    m_charging(false),
    m_present(false),
    m_status("Unknown")
    {
        probeBatteryPaths();
        refresh();

        QTimer* t = new QTimer(this);
        connect(t, &QTimer::timeout, this, &Battery::refresh);
        t->start(10000); // refresh every 10 seconds
    }

    int percent() const { return m_percent; }
    QString status() const { return m_status; }
    bool present() const { return m_present; }
    bool charging() const { return m_charging; }

    Q_INVOKABLE void refresh() {
        if (m_batteryPaths.isEmpty()) probeBatteryPaths();

        int sumPercent = 0;
        int count = 0;
        bool anyPresent = false;
        bool anyCharging = false;
        bool anyDischarging = false;
        bool anyFull = false;

        for (const auto &p : m_batteryPaths) {
            int cap = readIntFromFile(p + "/capacity", -1);
            QString st = readStringFromFile(p + "/status").trimmed().toLower();
            int pres = readIntFromFile(p + "/present", 1); // assume present if missing

            if (cap >= 0) {
                sumPercent += cap;
                count++;
            }

            if (pres == 1) anyPresent = true;

            if (st == "charging") anyCharging = true;
            else if (st == "discharging") anyDischarging = true;
            else if (st == "full") anyFull = true;
        }

        int newPercent = (count > 0) ? (sumPercent / count) : -1;

        QString newStatus = "Unknown";
        if (anyCharging && !anyFull) newStatus = "Charging";
        else if (anyFull) newStatus = "Full";
        else if (anyDischarging) newStatus = "Discharging";

        updateProperty(m_percent, newPercent, &Battery::percentChanged);
        updateProperty(m_status, newStatus, &Battery::statusChanged);
        updateProperty(m_present, anyPresent, &Battery::presentChanged);
        updateProperty(m_charging, anyCharging && !anyFull, &Battery::chargingChanged);
    }

signals:
    void percentChanged();
    void statusChanged();
    void presentChanged();
    void chargingChanged();

private:
    int m_percent;
    bool m_charging;
    bool m_present;
    QString m_status;
    QStringList m_batteryPaths;

    template<typename T>
    void updateProperty(T &property, const T &value, void (Battery::*signal)()) {
        if (property != value) {
            property = value;
            emit (this->*signal)();
        }
    }

    static int readIntFromFile(const QString &path, int fallback = -1) {
        QFile f(path);
        if (!f.open(QFile::ReadOnly | QFile::Text)) return fallback;
        bool ok = false;
        int val = QString(f.readAll().trimmed()).toInt(&ok);
        return ok ? val : fallback;
    }

    static QString readStringFromFile(const QString &path) {
        QFile f(path);
        if (!f.open(QFile::ReadOnly | QFile::Text)) return QString();
        return QString::fromUtf8(f.readAll());
    }

    void probeBatteryPaths() {
        m_batteryPaths.clear();
        QDir d("/sys/class/power_supply");
        if (!d.exists()) return;

        for (const QFileInfo &fi : d.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot)) {
            QString typeFile = fi.absoluteFilePath() + "/type";
            QString typeStr = readStringFromFile(typeFile).trimmed();
            if (typeStr.toLower().contains("battery") || fi.fileName().toLower().startsWith("bat")) {
                m_batteryPaths << fi.absoluteFilePath();
            }
        }
    }
};

class WindowController : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool visible READ visible NOTIFY visibleChanged)

public:
    explicit WindowController(QObject *parent = nullptr)
    : QObject(parent), m_window(nullptr), m_visible(false) {}

    void setWindow(QQuickWindow *window) {
        m_window = window;
        if (m_window)
            setVisible(m_window->isVisible());
    }

    bool visible() const {
        return m_visible;
    }

    Q_INVOKABLE void show() {
        setVisible(true);
    }

    Q_INVOKABLE void hide() {
        setVisible(false);
    }

    #include <QSharedMemory>

    Q_INVOKABLE void toggle() {
        // Check if Win8LockSingleton is running
        QSharedMemory win8LockCheck("Win8LockSingleton");
        if (win8LockCheck.attach()) {
            qWarning() << "⚠️ Win8LockSingleton is running → cannot toggle window";
            return;
        }

        setVisible(!m_visible);
    }


signals:
    void visibleChanged(bool visible);

private:
    QQuickWindow *m_window;
    bool m_visible;

    void setVisible(bool v) {
        if (m_visible == v || !m_window)
            return;

        m_visible = v;
        emit visibleChanged(m_visible);

        if (m_visible) {
            m_window->showFullScreen();
            m_window->raise();
            m_window->requestActivate();
        } else {
            m_window->hide();
        }
    }
};


class SingleInstance : public QObject {
    Q_OBJECT
public:
    explicit SingleInstance(const QString &name, QObject *parent = nullptr)
    : QObject(parent)
    {
        m_server = new QLocalServer(this);

        // Remove stale socket
        QLocalServer::removeServer(name);

        if (m_server->listen(name)) {
            connect(m_server, &QLocalServer::newConnection,
                    this, &SingleInstance::handleConnection);
        }
    }

signals:
    void activateRequested();

private:
    QLocalServer *m_server;

    void handleConnection() {
        QLocalSocket *socket = m_server->nextPendingConnection();
        if (!socket) return;

        socket->waitForReadyRead(100);
        QByteArray msg = socket->readAll();
        socket->disconnectFromServer();

        if (msg == "ACTIVATE")
            emit activateRequested();
    }
};



// ----------------------------
// main()
// ----------------------------
int main(int argc, char *argv[])
{
    // --------------------------------------------------------
    // Single-instance lock + activation
    // --------------------------------------------------------
    QString lockPath =
    QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation)
    + "/Win8Start.lock";

        QLockFile lockFile(lockPath);
        lockFile.setStaleLockTime(0);

        if (!lockFile.tryLock()) {
            QLocalSocket socket;
            socket.connectToServer("Win8StartInstance");
            if (socket.waitForConnected(100)) {
                socket.write("ACTIVATE");
                socket.flush();
                socket.waitForBytesWritten(100);
            }
            return 0;
        }

        QSharedMemory win8LockCheck("Win8LockSingleton");
        if (win8LockCheck.attach()) {
            qWarning() << "⚠️ Win8Lock is running. Win8Start will not start.";
            return 0;
        }

        QGuiApplication app(argc, argv);
        QQmlApplicationEngine engine;

        // --------------------------------------------------------
        // Battery
        // --------------------------------------------------------
        Battery battery;
        engine.rootContext()->setContextProperty("battery", &battery);

        // --------------------------------------------------------
        // Win8Settings path
        // --------------------------------------------------------
        const QString settingsPath =
        QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
        + "/Win8Settings/settings.ini";

            // --------------------------------------------------------
            // Helper: load Start wallpaper + colors
            // --------------------------------------------------------
            QString startWallpaper;
            QVariantMap win8Colors;

            auto loadSettings = [&]() {
                QSettings s(settingsPath, QSettings::IniFormat);

                // ---- Wallpaper (Start) ----
                s.beginGroup("Wallpaper");
                QString startPath = s.value("Start").toString();
                s.endGroup();

                if (!startPath.isEmpty() && QFileInfo::exists(startPath)) {
                    startWallpaper = QUrl::fromLocalFile(startPath).toString();
                    qDebug() << "🖼 Start wallpaper loaded:" << startWallpaper;
                } else {
                    startWallpaper = "qrc:/fallbacks/start-bg.png";
                    qWarning() << "⚠️ Using fallback start wallpaper";
                }

                // ---- Colors ----
                s.beginGroup("Colors");
                win8Colors["Background"] =
                s.value("Background", "#000000").toString();
                win8Colors["Tile"] =
                s.value("Tile", "#ffffff").toString();
                win8Colors["TileHighlight"] =
                s.value("TileHighlight", "#ff0000").toString();
                s.endGroup();
            };

            // Initial load
            loadSettings();

            engine.rootContext()->setContextProperty("startWallpaper", startWallpaper);
            engine.rootContext()->setContextProperty(
                "Win8Colors", QVariant::fromValue(win8Colors));

            // --------------------------------------------------------
            // File system watcher
            // --------------------------------------------------------
            QFileSystemWatcher watcher;

            if (QFileInfo::exists(settingsPath)) {
                watcher.addPath(settingsPath);
            } else {
                watcher.addPath(QFileInfo(settingsPath).absolutePath());
            }

            QObject::connect(&watcher, &QFileSystemWatcher::fileChanged,
                             [&](const QString &) {
                                 qDebug() << "🔄 settings.ini changed → reloading Start settings";

                                 loadSettings();

                                 engine.rootContext()->setContextProperty(
                                     "startWallpaper", startWallpaper);
                                 engine.rootContext()->setContextProperty(
                                     "Win8Colors", QVariant::fromValue(win8Colors));

                                 // Qt removes watched file after change → re-add
                                 if (!watcher.files().contains(settingsPath)
                                     && QFileInfo::exists(settingsPath)) {
                                     watcher.addPath(settingsPath);
                                     }
                             });

            // --------------------------------------------------------
            // Load QML
            // --------------------------------------------------------
            engine.load(QUrl(QStringLiteral("qrc:/main2.qml")));
            if (engine.rootObjects().isEmpty())
                return -1;

    QQuickWindow *window =
    qobject_cast<QQuickWindow*>(engine.rootObjects().first());
    if (!window)
        return -1;

    // --------------------------------------------------------
    // LayerShell configuration
    // --------------------------------------------------------
    auto layerWindow = LayerShellQt::Window::get(window);
    layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);
    layerWindow->setKeyboardInteractivity(
        LayerShellQt::Window::KeyboardInteractivityExclusive);
    layerWindow->setAnchors({
        LayerShellQt::Window::AnchorBottom,
        LayerShellQt::Window::AnchorLeft
    });
    layerWindow->setExclusiveZone(-1);
    layerWindow->setMargins({0, 0, 0, 0});

    window->setFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
    window->showFullScreen();

    // --------------------------------------------------------
    // Window controller
    // --------------------------------------------------------
    WindowController windowController;
    windowController.setWindow(window);

    QObject::connect(window, &QQuickWindow::activeChanged, [&]() {
        if (!window->isActive())
            windowController.hide();
    });

    // --------------------------------------------------------
    // Single-instance activation listener
    // --------------------------------------------------------
    SingleInstance instance("Win8StartInstance");
    QObject::connect(&instance, &SingleInstance::activateRequested, [&]() {
        windowController.toggle();
    });

    // --------------------------------------------------------
    // Backend objects
    // --------------------------------------------------------
    AppLauncher launcher;
    AppModel appModel;
    TileModel tileModel;
    PowerControl powerControl;
    Launcher launcherQml;

    engine.rootContext()->setContextProperty("AppLauncher", &launcher);
    engine.rootContext()->setContextProperty("appModel", &appModel);
    engine.rootContext()->setContextProperty("tileModel", &tileModel);
    engine.rootContext()->setContextProperty("powerControl", &powerControl);
    engine.rootContext()->setContextProperty("Launcher", &launcherQml);
    engine.rootContext()->setContextProperty(
        "WindowController", &windowController);

    // --------------------------------------------------------
    // Async application loading
    // --------------------------------------------------------
    QObject::connect(
        &launcher,
        &AppLauncher::applicationsLoaded,
        [&](const QVariantList &apps) {
            QList<AppInfo> appInfos;
            for (const QVariant &v : apps) {
                QVariantMap m = v.toMap();
                appInfos.append({
                    m["name"].toString(),
                                m["command"].toString(),
                                m["icon"].toString(),
                                m["desktopFilePath"].toString()
                });
            }
            appModel.setApps(appInfos);
        }
    );

    QTimer::singleShot(0, [&launcher]() {
        launcher.listApplicationsAsync();
    });

    return app.exec();
}

#include "main.moc"
