#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QAbstractListModel>
#include <QSettings>
#include <QProcess>
#include <QDir>
#include <QFileSystemWatcher>
#include <QFile>
#include <QLocalServer>
#include <QLocalSocket>
#include <QFileInfo>
#include <LayerShellQt/window.h>

/* ---------------- Window Item ---------------- */

struct WindowItem {
    QString appId;
    QString title;
    QString iconName;
    QString iconPath;
    bool focused;
    bool maximized;
    bool minimized;
};

/* ---------------- Window Model ---------------- */

class WindowModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles {
        AppIdRole = Qt::UserRole + 1,
        TitleRole,
        FocusedRole,
        MaximizedRole,
        MinimizedRole,
        IconPathRole
    };

    WindowModel(QObject *parent = nullptr)
    : QAbstractListModel(parent)
    {
        iniPath = QDir::homePath() + "/.config/list-windows/windows.ini";
        load();

        watcher.addPath(iniPath);
        connect(&watcher, &QFileSystemWatcher::fileChanged, this, [this] {
            if (!watcher.files().contains(iniPath))
                watcher.addPath(iniPath);
            reload();
        });
    }

    int rowCount(const QModelIndex &) const override {
        return windows.size();
    }

    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid()) return {};
        const auto &w = windows[index.row()];

        switch (role) {
            case AppIdRole: return w.appId;
            case TitleRole: return w.title;
            case FocusedRole: return w.focused;
            case MaximizedRole: return w.maximized;
            case MinimizedRole: return w.minimized;
            case IconPathRole: return w.iconPath;
        }
        return {};
    }

    QHash<int, QByteArray> roleNames() const override {
        return {
            {AppIdRole, "appId"},
            {TitleRole, "title"},
            {FocusedRole, "focused"},
            {MaximizedRole, "maximized"},
            {MinimizedRole, "minimized"},
            {IconPathRole, "iconPath"}
        };
    }

    Q_INVOKABLE void reload() {
        beginResetModel();
        windows.clear();
        load();
        endResetModel();
    }

    Q_INVOKABLE void activate(const QString &title)   { run({"--activate", title}); }
    Q_INVOKABLE void minimize(const QString &title)   { run({"--minimize", title}); }
    Q_INVOKABLE void maximize(const QString &title)   { run({"--maximize", title}); }
    Q_INVOKABLE void unmaximize(const QString &title) { run({"--unmaximize", title}); }
    Q_INVOKABLE void closeWindow(const QString &title){ run({"--close", title}); }

private:
    QList<WindowItem> windows;
    QFileSystemWatcher watcher;
    QString iniPath;

    void load() {
        QSettings ini(iniPath, QSettings::IniFormat);

        for (const QString &group : ini.childGroups()) {
            ini.beginGroup(group);
            WindowItem w;
            w.appId = ini.value("AppID").toString();
            w.title = ini.value("Title").toString();
            w.focused = ini.value("Focused").toBool();
            w.maximized = ini.value("Maximized").toBool();
            w.minimized = ini.value("Minimized").toBool();
            w.iconName = ini.value("Icon").toString();

            QFileInfo fi(w.iconName);
            if (fi.isAbsolute() && fi.exists())
                w.iconPath = "file://" + w.iconName;
            else
                w.iconPath = resolveIcon(w.iconName);

            windows.append(w);
            ini.endGroup();
        }
    }

    QString resolveIcon(const QString &name)
    {
        QString xdgDataHome = qEnvironmentVariable("XDG_DATA_HOME");
        if (xdgDataHome.isEmpty())
            xdgDataHome = QDir::homePath() + "/.local/share";

        QStringList basePaths = {
            xdgDataHome + "/icons/hicolor",
            QDir::homePath() + "/.icons",
            "/usr/share/icons/hicolor",
            "/usr/share/icons/breeze/apps",   // Breeze base
            "/usr/share/pixmaps"
        };

        QStringList sizes = {
            "scalable/apps",
            "256x256/apps",
            "128x128/apps",
            "64x64/apps",
            "48x48/apps",
            "64",   // Breeze
            "48"    // Breeze
        };

        for (const QString &base : basePaths) {
            for (const QString &size : sizes) {
                QString path = base + "/" + size + "/" + name;

                QString svg = path + ".svg";
                if (QFile::exists(svg))
                    return QUrl::fromLocalFile(svg).toString();

                QString png = path + ".png";
                if (QFile::exists(png))
                    return QUrl::fromLocalFile(png).toString();
            }

            // pixmaps (no size dir)
            QString pixmap = base + "/" + name + ".png";
            if (QFile::exists(pixmap))
                return QUrl::fromLocalFile(pixmap).toString();
        }

        return {};
    }

    void run(const QStringList &args) {
        QProcess::startDetached("list-windows", args);
    }
};

/* ---------------- Window Controller (NEW) ---------------- */

class WindowController : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool visible READ isVisible NOTIFY visibleChanged)

public:
    explicit WindowController(QQuickWindow *w, QObject *parent = nullptr)
    : QObject(parent), window(w) {}

    Q_INVOKABLE void show() {
        if (!window) return;
        window->show();
        emit visibleChanged();
    }

    Q_INVOKABLE void hide() {
        if (!window) return;
        window->hide();
        emit visibleChanged();
    }

    Q_INVOKABLE void toggle() {
        if (!window) return;
        window->setVisible(!window->isVisible());
        emit visibleChanged();
    }

    bool isVisible() const {
        return window && window->isVisible();
    }

signals:
    void visibleChanged();

private:
    QQuickWindow *window = nullptr;
};

/* ---------------- main() ---------------- */

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    qmlRegisterType<WindowModel>("Windows", 1, 0, "WindowModel");

    QString socketPath = QDir::homePath() + "/.config/window-switcher/toggle.sock";

    // Try to connect to an existing instance
    QLocalSocket sock;
    sock.connectToServer(socketPath);
    if (sock.waitForConnected(50)) {
        sock.write("toggle");
        sock.flush();
        return 0;  // Existing instance toggled, exit
    }

    // Load QML engine
    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty()) return -1;

    // Get the root window
    auto *window = qobject_cast<QQuickWindow*>(engine.rootObjects().first());

    /* ---------------- LayerShell setup ---------------- */
    auto layer = LayerShellQt::Window::get(window);
    layer->setLayer(LayerShellQt::Window::LayerOverlay);
    layer->setKeyboardInteractivity(
        LayerShellQt::Window::KeyboardInteractivityOnDemand);
    layer->setAnchors({
        LayerShellQt::Window::AnchorBottom,
        LayerShellQt::Window::AnchorLeft
    });
    layer->setExclusiveZone(-1);

    window->setFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
    window->show();

    /* ---------------- WindowController ---------------- */
    auto *controller = new WindowController(window, &app);
    engine.rootContext()->setContextProperty("WindowController", controller);

    /* ---------------- Toggle server ---------------- */
    QDir().mkpath(QFileInfo(socketPath).absolutePath());
    QFile::remove(socketPath);

    auto *server = new QLocalServer(&app);
    if (!server->listen(socketPath)) {
        qWarning() << "Failed to start toggle server:" << server->errorString();
        return -1;
    }

    QObject::connect(server, &QLocalServer::newConnection, [controller, server]() {
        auto *client = server->nextPendingConnection();
        QObject::connect(client, &QLocalSocket::readyRead, [controller, client]() {
            controller->toggle();
            client->disconnectFromServer();
            client->deleteLater();
        });
    });

    return app.exec();
}


#include "main.moc"
