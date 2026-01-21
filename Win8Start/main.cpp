// main.cpp
#include <LayerShellQt/window.h>
#include <QAbstractListModel>
#include <QCryptographicHash>
#include <QDir>
#include <QDrag>
#include <QFile>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QGuiApplication>
#include <QImage>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QList>
#include <QLockFile>
#include <QMimeData>
#include <QObject>
#include <QPixmap>
#include <QProcess>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickItem>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QString>

#include <QLocalServer>
#include <QLocalSocket>

#include <QDebug>
#include <QTimer>
#include <algorithm>
#include <pwd.h>
#include <unistd.h>

#include <QFutureWatcher>
#include <QtConcurrent>
#include <functional>

#include <QDBusInterface>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QVariantMap>
// ----------------------------
// Simple Async helper
// ----------------------------
class Async : public QObject {
  Q_OBJECT
public:
  explicit Async(QObject *parent = nullptr) : QObject(parent) {}

  template <typename Func, typename Callback>
  void run(Func func, Callback callback) {
    using R = decltype(func());
    QFuture<R> future = QtConcurrent::run(func);
    QFutureWatcher<R> *watcher = new QFutureWatcher<R>(this);

    // Capture the future by value and callback by value (copy)
    connect(watcher, &QFutureWatcher<R>::finished, this,
            [watcher, future, callback]() mutable {
              try {
                R result = future.result();
                callback(result);
              } catch (...) {
                // swallow exceptions to avoid crashing; callback may not be
                // called
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
  QStringList categories;
  bool terminal = false;
};

// ----------------------------
// AppModel class
// ----------------------------
class AppModel : public QAbstractListModel {
  Q_OBJECT
public:
  enum Roles {
    NameRole = Qt::UserRole + 1,
    CommandRole,
    IconRole,
    LetterRole,
    HeaderVisibleRole,
    DesktopFileRole,
    CategoriesRole,
    TerminalRole
  };
  
  AppModel(QObject *parent = nullptr) : QAbstractListModel(parent) {}
  
  void setApps(const QList<AppInfo> &apps) {
    beginResetModel();
    m_allApps = apps; // full list
    m_apps = apps;    // visible list
    endResetModel();
  }
  
  int rowCount(const QModelIndex &parent = QModelIndex()) const override {
    Q_UNUSED(parent);
    return m_apps.count();
  }
  
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_apps.count())
      return QVariant();
    
    const AppInfo &app = m_apps[index.row()];
    switch (role) {
      case NameRole: return app.name;
      case CommandRole: return app.command;
      case IconRole: return app.icon;
      case LetterRole: return app.name.left(1).toUpper();
      case HeaderVisibleRole:
        if (index.row() == 0) return true;
        return app.name.left(1).toUpper() != m_apps[index.row() - 1].name.left(1).toUpper();
      case DesktopFileRole: return app.desktopFilePath;
      case CategoriesRole: return app.categories;
      case TerminalRole: return app.terminal;
      
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
      {CategoriesRole, "categories"},
      {DesktopFileRole, "desktopFilePath"},
      {TerminalRole, "terminal"}
    };
  }
  
  // -------------------------------
  // Search apps by name
  // -------------------------------
  Q_INVOKABLE void search(const QString &query) {
    m_currentQuery = query.trimmed();
    applyFilter();
  }
  
  // -------------------------------
  // Filter by category
  // -------------------------------
  Q_INVOKABLE void setCategoryFilter(const QString &category) {
    m_selectedCategory = category.trimmed();
    applyFilter();
  }
  
private:
  QList<AppInfo> m_apps;       // filtered list
  QList<AppInfo> m_allApps;    // full list
  QString m_currentQuery;      // current search query
  QString m_selectedCategory;  // selected category filter
  
  // scores search relevance
  static int matchScore(const QString &name, const QString &query) {
    if (query.isEmpty())
      return 1000; // neutral score
      
      QString n = name.toLower();
    QString q = query.toLower();
    
    // Best: starts with query
    if (n.startsWith(q))
      return 0;
    
    // Next: any word starts with query
    const QStringList words = n.split(QRegularExpression("\\s+"));
    for (const QString &w : words) {
      if (w.startsWith(q))
        return 1;
    }
    
    // Next: contains query anywhere
    if (n.contains(q))
      return 2;
    
    // No match
    return 100;
  }
  
  // -------------------------------
  // Apply search + category filter
  // -------------------------------
  void applyFilter() {
    beginResetModel();
    m_apps.clear();
    
    struct ScoredApp {
      AppInfo app;
      int score;
    };
    
    QList<ScoredApp> scored;
    
    for (const auto &app : m_allApps) {
      // category filter
      bool matchesCategory =
      m_selectedCategory.isEmpty() ||
      app.categories.contains(m_selectedCategory, Qt::CaseInsensitive);
      
      if (!matchesCategory)
        continue;
      
      int score = matchScore(app.name, m_currentQuery);
      
      // reject non-matching search results
      if (!m_currentQuery.isEmpty() && score >= 100)
        continue;
      
      scored.append({ app, score });
    }
    
    // Sort by relevance score, then alphabetically
    std::sort(scored.begin(), scored.end(),
              [](const ScoredApp &a, const ScoredApp &b) {
                if (a.score != b.score)
                  return a.score < b.score;
                return a.app.name.toLower() < b.app.name.toLower();
              });
    
    for (const auto &s : scored)
      m_apps.append(s.app);
    
    endResetModel();
  }
  
};


struct DesktopAction {
    QString id;      // e.g. "NewWindow"
    QString name;    // visible name
    QString exec;    // Exec=
    QString icon;    // Icon=
};
class DesktopActionModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        CommandRole,
        IconRole
    };

    DesktopActionModel(QObject *parent = nullptr)
    : QAbstractListModel(parent) {}

    int rowCount(const QModelIndex &) const override {
        return m_actions.size();
    }

    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= m_actions.size())
            return {};

        const auto &a = m_actions[index.row()];
        switch (role) {
            case NameRole: return a.name;
            case CommandRole: return a.exec;
            case IconRole: return a.icon;
            default: return {};
        }
    }

    QHash<int, QByteArray> roleNames() const override {
        return {
            {NameRole, "name"},
            {CommandRole, "command"},
            {IconRole, "icon"},
        };
    }

    void setActions(const QList<DesktopAction> &actions) {
        beginResetModel();
        m_actions = actions;
        endResetModel();
    }

private:
    QList<DesktopAction> m_actions;
};

// ----------------------------
// AppLauncher class (FULL VERSION WITH CACHING + ASYNC)
// ----------------------------
class AppLauncher : public QObject {
  Q_OBJECT
public:
  explicit AppLauncher(QObject *parent = nullptr) : QObject(parent) {}

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
    m_async.run([this]() -> QVariantList { return listApplicationsSync(); },
                [this](QVariantList apps) { emit applicationsLoaded(apps); });
  }

  // ------------------------------------
  // Recheck for new apps on each showing
  // ------------------------------------
  // Already exists, just make it callable from QML
  Q_INVOKABLE void refreshApplications() {
      listApplicationsAsync();
  }

  // ------------------------------------
  // SYNC implementation with caching
  // ------------------------------------
  QVariantList listApplicationsSync() {
    QString configDir =
    QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir().mkpath(configDir);
    
    QString cacheFile = configDir + "/apps_cache_v1.json";
    QString hashFile = configDir + "/apps_cache_hash_v1.txt";
    
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
        if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) continue;
        
        QString name, exec, iconName;
        QStringList categories;   // <-- NEW: store categories
        bool noDisplay = false;
        bool inMainSection = false;
        bool terminal = false;   // <-- NEW
        
        
        while (!f.atEnd()) {
          QString line = f.readLine().trimmed();
          
          if (line.startsWith('[')) {
            if (line == "[Desktop Entry]")
              inMainSection = true;
            else if (line.startsWith("[Desktop Action"))
              break;
            else
              inMainSection = false;
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
          else if (line.startsWith("Categories="))
            categories = line.mid(11).split(';', Qt::SkipEmptyParts); // <-- PARSE CATEGORIES
            else if (line.startsWith("Terminal="))
              terminal = (line.mid(9).trimmed().toLower() == "true");
            else if (line.startsWith("NoDisplay=") && line.mid(10).trimmed().toLower() == "true")
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
        app["categories"] = categories;   // <-- STORE CATEGORIES
        app["terminal"] = terminal;
        
        appList.append(app);
      }
    }
    
    // Sort apps alphabetically
    std::sort(appList.begin(), appList.end(),
              [](const QVariant &a, const QVariant &b) {
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
  Q_INVOKABLE QString resolveIcon(const QString &name) const {
    if (name.isEmpty())
      return "qrc:/icons/placeholder.svg";

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
        home + "/.local/share/icons/hicolor/256x256/apps/"};

    for (const QString &dir : iconDirs) {
      QString pngPath = dir + name + ".png";
      QString svgPath = dir + name + ".svg";
      if (QFile::exists(pngPath))
        return "file://" + pngPath;
      if (QFile::exists(svgPath))
        return "file://" + svgPath;
    }

    return "qrc:/icons/placeholder.svg";
  }

  QList<DesktopAction> parseDesktopActions(const QString &desktopFile) {
      QList<DesktopAction> actions;
      QFile f(desktopFile);
      if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
          return actions;

      QString currentId;
      DesktopAction current;
      bool inAction = false;

      while (!f.atEnd()) {
          QString line = f.readLine().trimmed();

          if (line.startsWith("[Desktop Action ")) {
              if (inAction && !current.name.isEmpty() && !current.exec.isEmpty())
                  actions.append(current);

              current = DesktopAction{};
              currentId = line.mid(16, line.size() - 17);
              current.id = currentId;
              inAction = true;
              continue;
          }

          if (line.startsWith('[')) {
              if (inAction && !current.name.isEmpty() && !current.exec.isEmpty())
                  actions.append(current);
              inAction = false;
              continue;
          }

          if (!inAction)
              continue;

          if (line.startsWith("Name="))
              current.name = line.mid(5).trimmed();
          else if (line.startsWith("Exec=")) {
              current.exec = line.mid(5).trimmed();
              current.exec.replace(QRegularExpression("%[UuFfDdNnVvMm]"), "");
          } else if (line.startsWith("Icon="))
              current.icon = resolveIcon(line.mid(5).trimmed());
      }

      if (inAction && !current.name.isEmpty() && !current.exec.isEmpty())
          actions.append(current);

      return actions;
  }
  Q_INVOKABLE void loadDesktopActions(const QString &desktopFile,
                                      DesktopActionModel *model) {
    if (!model)
      return;

    QPointer<DesktopActionModel> safeModel(model);

    m_async.run(
      [this, desktopFile]() {
        return parseDesktopActions(desktopFile);
      },
      [safeModel](QList<DesktopAction> actions) {
        if (safeModel)
          safeModel->setActions(actions);
      });}



  // ------------------------------------
  // Launch application
  // ------------------------------------
  Q_INVOKABLE void launchApp(const QString &command, bool terminal) {
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
    if (parts.isEmpty())
        return;

    QString program = parts.takeFirst();
    QString programPath = QFile::exists(program)
                              ? program
                              : QStandardPaths::findExecutable(program);

    if (programPath.isEmpty()) {
        qWarning() << "❌ launchApp: Executable not found:" << program;
        return;
    }

    // 🟢 TERMINAL HANDLING
    if (terminal) {
      QString terminalExe = QStandardPaths::findExecutable("alacritty");
      
      if (terminalExe.isEmpty()) {
        qWarning() << "❌ Alacritty not found";
        return;
      }
      
      QStringList termArgs;
      termArgs << "-e" << programPath;
      termArgs << parts;
      
      QProcess::startDetached(terminalExe, termArgs);
    } else {
      QProcess::startDetached(programPath, parts);
    }
}


  // ------------------------------------
  // Drag to desktop
  // ------------------------------------
  Q_INVOKABLE void startSystemDrag(const QString &desktopFilePath,
                                   QQuickItem *iconItem) {
    if (!iconItem || !iconItem->window())
      return;

    QFileInfo fi(desktopFilePath);
    if (!fi.exists()) {
      qWarning() << "Desktop file not found:" << desktopFilePath;
      return;
    }

    QMimeData *mimeData = new QMimeData;
    mimeData->setUrls({QUrl::fromLocalFile(desktopFilePath)});

    QByteArray specialData(
        "copy\n" + QUrl::fromLocalFile(desktopFilePath).toEncoded() + "\n");
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
        drag->setHotSpot(QPoint(pix.width() / 2, pix.height() / 2));
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
        QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation)};

    for (const QString &dir : dirs) {
      QDir d(dir);
      if (!d.exists())
        continue;

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
    QString desktopName = name.endsWith(".desktop") ? name : name + ".desktop";

    QStringList dirs = {
        "/usr/share/applications",
        QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation)};

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
  bool terminal = false;
  double modelX;
  double modelY;
  QString size;
  QString color;
  QString qmlPath;   // external tile UI (optional)
  bool qmlEnabled = false;
  int qmlGeneration = 0;
};

Q_DECLARE_METATYPE(Tile)

class TileModel : public QAbstractListModel {
  Q_OBJECT

public:
  enum Roles {
    NameRole = Qt::UserRole + 1,
    IconRole,
    DesktopFileRole,
    CommandRole,
    TerminalRole,
    ModelXRole,
    ModelYRole,
    SizeRole,
    ColorRole,
    QmlPathRole,
    QmlEnabledRole,
    QmlGenerationRole
    
  };

  TileModel(QObject *parent = nullptr)
  : QAbstractListModel(parent) {
    loadAsync();
  }

  // -------------------------------------------------
  // Model basics
  // -------------------------------------------------

  int rowCount(const QModelIndex &parent = QModelIndex()) const override {
    Q_UNUSED(parent);
    return m_tiles.count();
  }

  QVariant data(const QModelIndex &index, int role) const override {
    if (!index.isValid() || index.row() >= m_tiles.count())
      return {};

    const Tile &t = m_tiles[index.row()];
    switch (role) {
      case NameRole:        return t.name;
      case IconRole:          return t.icon;
      case DesktopFileRole:   return t.desktopFile;
      case CommandRole:       return t.command;
      case TerminalRole:      return t.terminal;
      case ModelXRole:        return t.modelX;
      case ModelYRole:        return t.modelY;
      case SizeRole:          return t.size;
      case ColorRole:         return t.color;
      case QmlPathRole:       return t.qmlPath;
      case QmlEnabledRole:    return t.qmlEnabled;
      case QmlGenerationRole: return t.qmlGeneration;
      default:                return {};
    }
  }

  QHash<int, QByteArray> roleNames() const override {
    return {
      {NameRole,          "name"},
      {IconRole,          "icon"},
      {DesktopFileRole,   "desktopFile"},
      {CommandRole,       "command"},
      {ModelXRole,        "modelX"},
      {ModelYRole,        "modelY"},
      {TerminalRole,      "terminal"},
      {SizeRole,          "size"},
      {ColorRole,         "tileColor"},
      {QmlPathRole,       "tileQml" },
      {QmlEnabledRole,    "qmlEnabled"},
      {QmlGenerationRole, "qmlGeneration"}
      
      
    };
  }

  // -------------------------------------------------
  // Tile manipulation (QML invokable)
  // -------------------------------------------------

  Q_INVOKABLE void updateTilePosition(int index, double x, double y) {
    if (index < 0 || index >= m_tiles.count())
      return;

    m_tiles[index].modelX = x;
    m_tiles[index].modelY = y;

    emit dataChanged(
      this->index(index),
                     this->index(index),
                     { ModelXRole, ModelYRole }
    );

    saveAsync();
  }

  Q_INVOKABLE void resizeTile(int index, const QString &size) {
    if (index < 0 || index >= m_tiles.count())
      return;

    m_tiles[index].size = size;
    emit dataChanged(
      this->index(index),
                     this->index(index),
                     { SizeRole }
    );

    saveAsync();
  }

  Q_INVOKABLE void removeTile(int index) {
    if (index < 0 || index >= m_tiles.count())
      return;

    beginRemoveRows(QModelIndex(), index, index);
    m_tiles.removeAt(index);
    endRemoveRows();

    saveAsync();
  }

  // -------------------------------------------------
  // Async add from .desktop file
  // -------------------------------------------------

  Q_INVOKABLE void addTileFromDesktopFile(
    const QString &filePath,
    double dropX,
    double dropY) {

    m_async.run(
      [=]() -> Tile {
        Tile t;
        t.terminal = false;
        t.desktopFile = filePath;
        t.modelX = dropX;
        t.modelY = dropY;
        t.size = "medium";

        QFile f(filePath);
        if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
          t.name = QFileInfo(filePath).baseName();
          return t;
        }

        bool inMainSection = false;

        while (!f.atEnd()) {
          QString line = f.readLine().trimmed();

          if (line.startsWith('[')) {
            if (line == "[Desktop Entry]") {
              inMainSection = true;
            } else if (line.startsWith("[Desktop Action")) {
              break;
            } else {
              inMainSection = false;
            }
            continue;
          }

          if (!inMainSection)
            continue;

          if (line.startsWith("Name="))
            t.name = line.mid(5).trimmed();
          else if (line.startsWith("Icon="))
            t.icon = line.mid(5).trimmed();
          else if (line.startsWith("Terminal="))
            t.terminal = (line.mid(9).trimmed().toLower() == "true");
          else if (line.startsWith("Exec=")) {
            t.command = line.mid(5).trimmed();
            t.command.replace(
              QRegularExpression("%[UuFfDdNnVvMm]"), "");
          }
        }

        if (t.name.isEmpty())
          t.name = QFileInfo(filePath).baseName();

        return t;
      },
      [this](Tile t) {
        beginInsertRows(QModelIndex(), m_tiles.count(), m_tiles.count());
        m_tiles.append(t);
        endInsertRows();

        saveAsync();
        qDebug() << "✅ Added tile:" << t.name;
      }
    );
    }
    
    Q_INVOKABLE void setTileColor(int index, const QString &color) {
      if (index < 0 || index >= m_tiles.count())
        return;
      
      m_tiles[index].color = color;
      
      emit dataChanged(
        this->index(index),
                       this->index(index),
                       { ColorRole }
      );
      
      saveAsync();
    }
    
    Q_INVOKABLE void resetTileColor(int index) {
      if (index < 0 || index >= m_tiles.count())
        return;
      
      m_tiles[index].color.clear(); // "" = default
      
      emit dataChanged(
        this->index(index),
                       this->index(index),
                       { ColorRole }
      );
      
      saveAsync();
    }
    
    QString tileRoot() const {
      return QStandardPaths::writableLocation(
        QStandardPaths::AppConfigLocation
      ) + "/tiles";
    }
    
    // Add this member to TileModel
    QSet<QString> m_logicRan; // Add this to your TileModel private members
     
     Q_INVOKABLE void setTileQml(int index, const QString &path)
     {
       if (index < 0 || index >= m_tiles.count())
         return;
       
       QString qmlPath = path;
       
       // ---- Resolve tile.qml path ----
       if (path.endsWith(".qml") && QFile::exists(path)) {
         qmlPath = path; // absolute path
       } else if (!path.contains('/')) {
         qmlPath = tileRoot() + "/" + path + "/tile.qml";
       } else if (QDir::isRelativePath(path)) {
         qmlPath = tileRoot() + "/" + path;
       }
       
       QFileInfo qmlInfo(qmlPath);
       QDir tileDir = qmlInfo.dir();
       
       if (!qmlInfo.exists())
         return;
       
       // ---- Assign QML path (only if changed) ----
       if (m_tiles[index].qmlPath != qmlPath) {
         m_tiles[index].qmlPath = qmlPath;
         emit dataChanged(this->index(index), this->index(index), { QmlPathRole });
         qDebug() << "🧩 Tile QML loaded:" << m_tiles[index].name;
       }
       
       if (!m_tiles[index].qmlEnabled)
         return;
       
       // ---- Run logic.py once ----
       QString logicPath = tileDir.filePath("logic.py");
       if (QFile::exists(logicPath) && !m_logicRan.contains(logicPath)) {
         m_logicRan.insert(logicPath);
         
         qDebug() << "⚡ logic.py running for tile:" << m_tiles[index].name;
         
         QProcess *p = new QProcess(this);
         p->setProgram("python3");
         p->setArguments({ logicPath });
         p->setWorkingDirectory(tileDir.absolutePath());
         
         connect(p, &QProcess::finished, this, [p](int, QProcess::ExitStatus) {
           p->deleteLater();
         });
         
         connect(p, &QProcess::errorOccurred, this, [p](QProcess::ProcessError) {
           p->deleteLater();
         });
         
         p->start();
       }
     }
     
     Q_INVOKABLE void setTileQmlEnabled(int index, bool enabled)
     {
       if (index < 0 || index >= m_tiles.count())
         return;
       
       if (m_tiles[index].qmlEnabled == enabled)
         return;
       
       m_tiles[index].qmlEnabled = enabled;
       emit dataChanged(this->index(index), this->index(index), { QmlEnabledRole });
       saveAsync();
       
       if (enabled && !m_tiles[index].qmlPath.isEmpty()) {
         QString qmlPath = m_tiles[index].qmlPath;
         QFileInfo qmlInfo(qmlPath);
         QDir tileDir = qmlInfo.dir();
         QString logicPath = tileDir.filePath("logic.py");
         
         if (QFile::exists(logicPath) && !m_logicRan.contains(logicPath)) {
           m_logicRan.insert(logicPath);
           qDebug() << "⚡ logic.py running for tile:" << m_tiles[index].name;
           
           QProcess *p = new QProcess(this);
           p->setProgram("python3");
           p->setArguments({ logicPath });
           p->setWorkingDirectory(tileDir.absolutePath());
           
           connect(p, &QProcess::finished, this, [p](int, QProcess::ExitStatus) {
             p->deleteLater();
           });
           
           connect(p, &QProcess::errorOccurred, this, [p](QProcess::ProcessError) {
             p->deleteLater();
           });
           
           p->start();
         }
       }
     }
     
     Q_INVOKABLE void toggleTileQml(int index)
     {
       setTileQmlEnabled(index, !m_tiles[index].qmlEnabled);
     }
     
     Q_INVOKABLE void reloadTileQml(int index)
     {
       if (index < 0 || index >= m_tiles.count())
         return;
       
       m_tiles[index].qmlGeneration++;
       emit dataChanged(this->index(index), this->index(index), { QmlGenerationRole });
     }
     
    

    // -------------------------------------------------
    // Async load / save
    // -------------------------------------------------

    void loadAsync() {
      m_async.run(
        [this]() -> QList<Tile> {
          QList<Tile> tiles;
          QFile file(jsonPath());
          if (!file.open(QIODevice::ReadOnly))
            return tiles;

          QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
          for (const auto &v : doc.array()) {
            QJsonObject o = v.toObject();
            Tile t;
            t.name        = o["name"].toString();
            t.icon        = o["icon"].toString();
            t.desktopFile = o["desktopFile"].toString();
            t.command     = o["command"].toString();
            t.modelX      = o["modelX"].toDouble();
            t.modelY      = o["modelY"].toDouble();
            t.size        = o["size"].toString("medium");
            t.terminal    = o.value("terminal").toBool(false);
            t.color       = o.value("color").toString("");
            t.qmlPath = o.value("qmlPath").toString("");
            t.qmlEnabled = o.value("qmlEnabled").toBool(false);
            tiles.append(t);
          }
          return tiles;
        },
        [this](QList<Tile> tiles) {
          beginResetModel();
          m_tiles = tiles;
          endResetModel();
          qDebug() << "✅ TileModel loaded:" << m_tiles.size();
        }
      );
    }

    void saveAsync() const {
      QList<Tile> tiles = m_tiles;
      
      // 🔽 SORT: lowest modelX first, then lowest modelY
      std::sort(tiles.begin(), tiles.end(),
                [](const Tile &a, const Tile &b) {
                  if (!qFuzzyCompare(a.modelX, b.modelX))
                    return a.modelX < b.modelX;
                  return a.modelY < b.modelY;
                }
      );
      
      Async *async = new Async(const_cast<TileModel *>(this));
      
      async->run(
        [tiles, this]() -> bool {
          QJsonArray arr;
          for (const auto &t : tiles) {
            QJsonObject o;
            o["name"]        = t.name;
            o["icon"]        = t.icon;
            o["desktopFile"] = t.desktopFile;
            o["command"]     = t.command;
            o["modelX"]      = t.modelX;
            o["modelY"]      = t.modelY;
            o["size"]        = t.size;
            o["terminal"]    = t.terminal;
            o["color"]       = t.color;
            o["qmlPath"]     = t.qmlPath;
            o["qmlEnabled"]  = t.qmlEnabled;
            arr.append(o);
          }
          
          QFile file(jsonPath());
          QDir().mkpath(QFileInfo(file).absolutePath());
          if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
            return false;
          
          file.write(QJsonDocument(arr).toJson(QJsonDocument::Indented));
          return true;
        },
        [](bool) {}
      );
    }
    

private:
  QList<Tile> m_tiles;
  Async m_async;

  QString jsonPath() const {
    return QStandardPaths::writableLocation(
      QStandardPaths::AppConfigLocation)
    + "/launcher_tiles.json";
  }
};


// ----------------------------
// PowerControl
// ----------------------------
class PowerControl : public QObject {
  Q_OBJECT
public:
  explicit PowerControl(QObject *parent = nullptr) : QObject(parent) {}

  Q_INVOKABLE void shutdown() {
    QProcess::startDetached("systemctl", {"poweroff"});
  }
  Q_INVOKABLE void reboot() {
    QProcess::startDetached("systemctl", {"reboot"});
  }
  Q_INVOKABLE void suspend() {
    QProcess::startDetached("systemctl", {"suspend"});
  }
  Q_INVOKABLE void logout() {
    QProcess::startDetached(
        "bash",
        {"-c", "swaymsg exit || niri msg action quit || hyprctl dispatch exit "
               "|| labwc -e || loginctl terminate-user $USER"});
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
  explicit Battery(QObject *parent = nullptr)
  : QObject(parent),
  m_percent(-1),
  m_present(false),
  m_charging(false),
  m_status("Unknown") {

    m_iface = new QDBusInterface(
      "org.freedesktop.UPower",
      "/org/freedesktop/UPower/devices/DisplayDevice",
      "org.freedesktop.UPower.Device",
      QDBusConnection::systemBus(),
                                 this);

    if (!m_iface->isValid())
      return;

    // Initial read (one-time)
    readAllProperties();

    // Listen for DBus updates
    QDBusConnection::systemBus().connect(
      "org.freedesktop.UPower",
      "/org/freedesktop/UPower/devices/DisplayDevice",
      "org.freedesktop.DBus.Properties",
      "PropertiesChanged",
      this,
      SLOT(onPropertiesChanged(QString, QVariantMap, QStringList)));
  }

  int percent() const { return m_percent; }
  QString status() const { return m_status; }
  bool present() const { return m_present; }
  bool charging() const { return m_charging; }

signals:
  void percentChanged();
  void statusChanged();
  void presentChanged();
  void chargingChanged();

private slots:
  void onPropertiesChanged(const QString &iface,
                           const QVariantMap &changed,
                           const QStringList &) {
    if (iface != "org.freedesktop.UPower.Device")
      return;

    if (changed.contains("Percentage")) {
      updateProperty(
        m_percent,
        int(changed.value("Percentage").toDouble() + 0.5),
                     &Battery::percentChanged);
    }

    if (changed.contains("IsPresent")) {
      updateProperty(
        m_present,
        changed.value("IsPresent").toBool(),
                     &Battery::presentChanged);
    }

    if (changed.contains("State")) {
      updateState(changed.value("State").toUInt());
    }
                           }

private:
  int m_percent;
  bool m_present;
  bool m_charging;
  QString m_status;

  QDBusInterface *m_iface;

  void readAllProperties() {
    updateProperty(m_percent,
                   reflect<int>("Percentage"),
                   &Battery::percentChanged);

    updateProperty(m_present,
                   reflect<bool>("IsPresent"),
                   &Battery::presentChanged);

    updateState(reflect<uint>("State"));
  }

  template<typename T>
  T reflect(const char *prop) {
    return m_iface->property(prop).value<T>();
  }

  void updateState(uint state) {
    QString newStatus = "Unknown";
    bool newCharging = false;

    // UPower states:
    // 1 = Charging
    // 2 = Discharging
    // 4 = Fully charged
    switch (state) {
      case 1:
        newStatus = "Charging";
        newCharging = true;
        break;
      case 2:
        newStatus = "Discharging";
        break;
      case 4:
        newStatus = "Full";
        break;
    }

    updateProperty(m_status, newStatus, &Battery::statusChanged);
    updateProperty(m_charging, newCharging, &Battery::chargingChanged);
  }

  template <typename T>
  void updateProperty(T &property, const T &value, void (Battery::*signal)()) {
    if (property != value) {
      property = value;
      emit (this->*signal)();
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

  bool visible() const { return m_visible; }

  Q_INVOKABLE void show() { setVisible(true); }

  Q_INVOKABLE void hide() { setVisible(false); }

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
      : QObject(parent) {
    m_server = new QLocalServer(this);

    // Remove stale socket
    QLocalServer::removeServer(name);

    if (m_server->listen(name)) {
      connect(m_server, &QLocalServer::newConnection, this,
              &SingleInstance::handleConnection);
    }
  }

signals:
  void activateRequested();

private:
  QLocalServer *m_server;

  void handleConnection() {
    QLocalSocket *socket = m_server->nextPendingConnection();
    if (!socket)
      return;

    socket->waitForReadyRead(100);
    QByteArray msg = socket->readAll();
    socket->disconnectFromServer();

    if (msg == "ACTIVATE")
      emit activateRequested();
  }
};

static QString monitorConfigPath()
{
  return QStandardPaths::writableLocation(
    QStandardPaths::ConfigLocation
  ) + "/Win8Start/monitor.ini";
}

static QString readPreferredOutput()
{
  QSettings s(monitorConfigPath(), QSettings::IniFormat);
  return s.value("StartMenu/Output").toString().trimmed();
}

static void writePreferredOutput(const QString &output)
{
  QSettings s(monitorConfigPath(), QSettings::IniFormat);
  s.setValue("StartMenu/Output", output);
  s.sync();
}


// ----------------------------
// main()
// ----------------------------
int main(int argc, char *argv[]) {
  
  qputenv("QML_XHR_ALLOW_FILE_READ", QByteArray("1"));
  // --------------------------------------------------------
  // Single-instance lock + activation
  // --------------------------------------------------------
  QString lockPath =
      QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) +
      "/Win8Start.lock";

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
      QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) +
      "/Win8Settings/settings.ini";

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
    win8Colors["Background"] = s.value("Background", "#000000").toString();
    win8Colors["Tile"] = s.value("Tile", "#ffffff").toString();
    win8Colors["TileHighlight"] =
        s.value("TileHighlight", "#ff0000").toString();
    s.endGroup();
  };

  // Initial load
  loadSettings();

  engine.rootContext()->setContextProperty("startWallpaper", startWallpaper);
  engine.rootContext()->setContextProperty("Win8Colors",
                                           QVariant::fromValue(win8Colors));

  // --------------------------------------------------------
  // File system watcher
  // --------------------------------------------------------
  QFileSystemWatcher watcher;

  if (QFileInfo::exists(settingsPath)) {
    watcher.addPath(settingsPath);
  } else {
    watcher.addPath(QFileInfo(settingsPath).absolutePath());
  }

  QObject::connect(
      &watcher, &QFileSystemWatcher::fileChanged, [&](const QString &) {
        qDebug() << "🔄 settings.ini changed → reloading Start settings";

        loadSettings();

        engine.rootContext()->setContextProperty("startWallpaper",
                                                 startWallpaper);
        engine.rootContext()->setContextProperty(
            "Win8Colors", QVariant::fromValue(win8Colors));

        // Qt removes watched file after change → re-add
        if (!watcher.files().contains(settingsPath) &&
            QFileInfo::exists(settingsPath)) {
          watcher.addPath(settingsPath);
        }
      });

  // --------------------------------------------------------
  // Load QML
  // --------------------------------------------------------
  engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
  if (engine.rootObjects().isEmpty())
    return -1;

  QQuickWindow *window =
      qobject_cast<QQuickWindow *>(engine.rootObjects().first());
  if (!window)
    return -1;

  // --------------------------------------------------------
  // LayerShell configuration
  // --------------------------------------------------------
  auto layerWindow = LayerShellQt::Window::get(window);
  layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);
  
  QList<QScreen*> screens = QGuiApplication::screens();
  QString preferredOutput = readPreferredOutput();
  
  QScreen *chosenScreen = nullptr;
  
  // 1️⃣ Try config value
  if (!preferredOutput.isEmpty()) {
    for (QScreen *s : screens) {
      if (s->name() == preferredOutput) {
        chosenScreen = s;
        break;
      }
    }
  }
  
  // 2️⃣ Fallback → first available screen
  if (!chosenScreen && !screens.isEmpty()) {
    chosenScreen = screens.first();
    writePreferredOutput(chosenScreen->name());
    qDebug() << "🖥 Monitor config missing → saved default:"
    << chosenScreen->name();
  }
  
  // 3️⃣ Bind LayerShell to chosen output
  if (chosenScreen) {
    window->setScreen(chosenScreen);
    
    qDebug() << "🖥 Start menu bound to:" << chosenScreen->name();
  }
  
  // Rest stays the same
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
  QObject::connect(&instance, &SingleInstance::activateRequested,
                   [&]() { windowController.toggle(); });

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
  engine.rootContext()->setContextProperty("WindowController",
                                           &windowController);
  DesktopActionModel actionModel;
  engine.rootContext()->setContextProperty("actionModel", &actionModel);

  // --------------------------------------------------------
  // Async application loading
  // --------------------------------------------------------
  QObject::connect(&launcher, &AppLauncher::applicationsLoaded,
                   [&](const QVariantList &apps) {
                     QList<AppInfo> appInfos;
                     for (const QVariant &v : apps) {
                       QVariantMap m = v.toMap();
                       appInfos.append({
                         m["name"].toString(),
                         m["command"].toString(),
                         m["icon"].toString(),
                         m["desktopFilePath"].toString(),
                         m["categories"].toStringList()  ,
                         m.value("terminal", false).toBool()
                       });
                       
                     }
                     appModel.setApps(appInfos);
                   });

  QTimer::singleShot(0, [&launcher]() { launcher.listApplicationsAsync(); });

  QObject::connect(&windowController, &WindowController::visibleChanged,
                   [&](bool visible) {
                     if (visible) {
                       qDebug() << "🔄 Start shown → reloading live tiles";
                       for (int i = 0; i < tileModel.rowCount(); ++i)
                         tileModel.reloadTileQml(i);
                     }
                   });
  


  return app.exec();
}

#include "main.moc"
