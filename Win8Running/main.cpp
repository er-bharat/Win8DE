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
#include <QTimer>
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

    Q_INVOKABLE void activate(int i) {
        if (i < 0 || i >= windows.size()) return;
        run({"--activate", windows[i].title});
        emit requestKeyboardRelease();
    }

    Q_INVOKABLE void activateOnly(int i) {
        if (i < 0 || i >= windows.size()) return;
        run({"--activate-only", windows[i].title});
        emit requestKeyboardRelease();
    }

    Q_INVOKABLE void minimize(int i) {
        if (i < 0 || i >= windows.size()) return;
        run({"--minimize", windows[i].title});
    }

    Q_INVOKABLE void maximize(int i) {
        if (i < 0 || i >= windows.size()) return;
        run({"--maximize", windows[i].title});
        emit requestKeyboardRelease();
    }

    Q_INVOKABLE void unmaximize(int i) {
        if (i < 0 || i >= windows.size()) return;
        run({"--unmaximize", windows[i].title});
        emit requestKeyboardRelease();
    }

    Q_INVOKABLE void close(int i) {
        if (i < 0 || i >= windows.size()) return;
        run({"--close", windows[i].title});
    }
    
    Q_INVOKABLE int indexOfFocused() const {
        for (int i = 0; i < windows.size(); ++i) {
            if (windows[i].focused)
                return i;
        }
        return -1;
    }
    

private:
    QList<WindowItem> windows;
    QFileSystemWatcher watcher;
    QString iniPath;

    void load() {
        QSettings ini(iniPath, QSettings::IniFormat);
         
        QStringList groups = ini.childGroups();
          
        // 🔹 Sort groups numerically: "1", "2", "10" (not lexicographically)
        std::sort(groups.begin(), groups.end(),
                  [](const QString &a, const QString &b) {
                      return a.toInt() < b.toInt();
                  });
                   
        for (const QString &group : groups) {
            ini.beginGroup(group);

            WindowItem w;
            w.appId     = ini.value("AppID").toString();
            w.title     = ini.value("Title").toString();
            w.focused   = ini.value("Focused").toBool();
            w.maximized = ini.value("Maximized").toBool();
            w.minimized = ini.value("Minimized").toBool();
            w.iconName  = ini.value("Icon").toString();

            QFileInfo fi(w.iconName);
            if (fi.isAbsolute() && fi.exists())
                w.iconPath = QUrl::fromLocalFile(w.iconName).toString();
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
            "/usr/share/icons/breeze/apps",
            "/usr/share/pixmaps"
        };

        QStringList sizes = {
            "scalable/apps",
            "256x256/apps",
            "128x128/apps",
            "64x64/apps",
            "48x48/apps",
            "64",
            "48"
        };

        for (const QString &base : basePaths) {

            // 🔹 pixmaps: search directly, no size directories
            if (base == "/usr/share/pixmaps") {
                QString png = base + "/" + name + ".png";
                if (QFile::exists(png))
                    return QUrl::fromLocalFile(png).toString();

                QString svg = base + "/" + name + ".svg";
                if (QFile::exists(svg))
                    return QUrl::fromLocalFile(svg).toString();

                continue;
            }

            // 🔹 icon themes: search with sizes
            for (const QString &size : sizes) {
                QString path = base + "/" + size + "/" + name;

                QString svg = path + ".svg";
                if (QFile::exists(svg))
                    return QUrl::fromLocalFile(svg).toString();

                QString png = path + ".png";
                if (QFile::exists(png))
                    return QUrl::fromLocalFile(png).toString();
            }
        }

        return {};
    }


    void run(const QStringList &args) {
        QProcess::startDetached("list-windows", args);
    }
signals:
    void requestKeyboardRelease();
    
};

/* ---------------- Window Controller (NEW) ---------------- */

class WindowController : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool visible READ isVisible NOTIFY visibleChanged)
    Q_PROPERTY(bool exclusive READ isExclusive NOTIFY exclusiveChanged)

public:
    explicit WindowController(QQuickWindow *w,
                              LayerShellQt::Window *layer,
                              QObject *parent = nullptr)
    : QObject(parent), window(w), layerShell(layer) {}

    Q_INVOKABLE void toggleExclusive() {
        if (!window || !layerShell) return;

        exclusive = !exclusive;
        qDebug() << "toggleExclusive called, new exclusive:" << exclusive;

        if (exclusive) {
            layerShell->setExclusiveZone(window->width());
        } else {
            layerShell->setExclusiveZone(0); // safer than -1
        }

        // Force layout refresh
        window->requestUpdate();

        emit exclusiveChanged();
    }
    bool isExclusive() const { return exclusive; }

    Q_INVOKABLE void releaseKeyboardMomentarily(int ms = 80)
    {
        if (!layerShell || !window)
            return;
        
        // 1️⃣ Make surface unfocusable
        layerShell->setKeyboardInteractivity(
            LayerShellQt::Window::KeyboardInteractivityNone);
        
        // Ensure the request is sent to the compositor
        window->requestUpdate();
        QGuiApplication::processEvents(QEventLoop::AllEvents, 1);
        
        // 2️⃣ Restore exclusive focus after a short delay
        QTimer::singleShot(ms, this, [this]() {
            if (!layerShell || !window)
                return;
            
            layerShell->setKeyboardInteractivity(
                LayerShellQt::Window::KeyboardInteractivityExclusive);
            
            window->requestUpdate();
        });
    }
    

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
    // void visibleChanged();
    void exclusiveChanged();

private:
    QQuickWindow *window = nullptr;
    LayerShellQt::Window *layerShell = nullptr;
    bool exclusive = false;
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
        LayerShellQt::Window::KeyboardInteractivityExclusive);
    layer->setAnchors({
        LayerShellQt::Window::AnchorTop,
        LayerShellQt::Window::AnchorBottom,
        LayerShellQt::Window::AnchorLeft
    });
    layer->setExclusiveZone(0);

    window->setFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
    window->show();

    /* ---------------- WindowController ---------------- */
    auto *controller = new WindowController(window, layer, &app);
    engine.rootContext()->setContextProperty("WindowController", controller);

    auto *model = engine.rootObjects().first()
    ->findChild<WindowModel *>();
    
    QObject::connect(model, &WindowModel::requestKeyboardRelease,
                     controller, [controller]() {
                         controller->releaseKeyboardMomentarily();
                     });
    
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
