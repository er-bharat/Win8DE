#include "lockmanager.h"

#include <LayerShellQt/window.h>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QScreen>
#include <QSettings>
#include <QSharedMemory>
#include <QStandardPaths>
#include <QTimer>

// -------------------------------------------------
// ORIGINAL GLOBALS (unchanged)
// -------------------------------------------------
QQuickWindow *window = nullptr;
LayerShellQt::Window *layerWindow = nullptr;
QQmlApplicationEngine *engine = nullptr;

// -------------------------------------------------
// ADD: secondary windows
// -------------------------------------------------
struct SecondaryWindow {
  QScreen *screen;
  QQmlApplicationEngine *engine;
  QQuickWindow *window;
  LayerShellQt::Window *layer;
};

QList<SecondaryWindow *> secondaryWindows;

// -------------------------------------------------
// ORIGINAL LayerShell setup (unchanged for primary)
// -------------------------------------------------
void setupLayerShell(QQuickWindow *w, bool primary) {
  if (!w)
    return;

  auto *layer = LayerShellQt::Window::get(w);

  layer->setLayer(LayerShellQt::Window::LayerOverlay);
  layer->setScope("lockscreen");

  layer->setKeyboardInteractivity(
      primary ? LayerShellQt::Window::KeyboardInteractivityExclusive
              : LayerShellQt::Window::KeyboardInteractivityNone);

  layer->setAnchors(
      {LayerShellQt::Window::AnchorTop, LayerShellQt::Window::AnchorBottom,
       LayerShellQt::Window::AnchorLeft, LayerShellQt::Window::AnchorRight});

  layer->setExclusiveZone(-1);

  w->setFlags(Qt::Window | Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
  w->show();
}

// -------------------------------------------------
// ORIGINAL destroy (primary only)
// -------------------------------------------------
void destroyLayerShell() {
  if (layerWindow) {
    layerWindow->deleteLater();
    layerWindow = nullptr;
  }
  if (window) {
    window->hide();
    window->deleteLater();
    window = nullptr;
  }

  // ALSO destroy secondary windows
  for (auto *s : secondaryWindows) {
    if (s->window)
      s->window->deleteLater();
    if (s->engine)
      s->engine->deleteLater();
    delete s;
  }
  secondaryWindows.clear();
}

// -------------------------------------------------
// ORIGINAL retry logic (primary only)
// -------------------------------------------------
void tryAttachWindow() {
  if (!window)
    return;

  QScreen *s = window->screen();
  if (!s || s->geometry().width() < 2 || s->geometry().height() < 2) {
    qDebug() << "Window not on a valid screen, retrying...";
    QTimer::singleShot(500, tryAttachWindow);
    return;
  }

  qDebug() << "Attaching LayerShell to PRIMARY screen:" << s->name();
  setupLayerShell(window, true);
}

// -------------------------------------------------
// LOAD QML (slightly generalized)
// -------------------------------------------------
void loadQml(QQmlApplicationEngine *eng, const QUrl &qmlUrl) {
  static LockManager lockManager;
  eng->rootContext()->setContextProperty("lockManager", &lockManager);

  QString userName = qgetenv("USER");
  if (userName.isEmpty())
    userName = qgetenv("USERNAME");
  eng->rootContext()->setContextProperty("systemUsername", userName);

  QString avatarPath =
      QString("/var/lib/AccountsService/icons/%1").arg(userName);

  QString avatarUrl = QFileInfo::exists(avatarPath)
                          ? QUrl::fromLocalFile(avatarPath).toString()
                          : "qrc:/images/default-avatar.png";

  eng->rootContext()->setContextProperty("userAvatar", avatarUrl);

  QString win8SettingsPath =
      QDir(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation))
          .filePath("Win8Settings/settings.ini");

  QSettings win8Settings(win8SettingsPath, QSettings::IniFormat);

  QVariantMap Win8Colors;
  win8Settings.beginGroup("Colors");
  Win8Colors["background"] = win8Settings.value("Background", "#000000");
  Win8Colors["tile"] = win8Settings.value("Tile", "#ffffff");
  Win8Colors["tileHighlight"] = win8Settings.value("TileHighlight", "#ff0000");
  win8Settings.endGroup();

  eng->rootContext()->setContextProperty("Win8Colors",
                                         QVariant::fromValue(Win8Colors));

  win8Settings.beginGroup("Wallpaper");
  QString lockscreenPath = win8Settings.value("Lockscreen").toString();
  win8Settings.endGroup();

  QString lockscreenWallpaper =
      QFileInfo::exists(lockscreenPath)
          ? QUrl::fromLocalFile(lockscreenPath).toString()
          : "";

  eng->rootContext()->setContextProperty("wallpaperPath", lockscreenWallpaper);

  eng->load(qmlUrl);
}

// -------------------------------------------------
// ORIGINAL createWindowIfNeeded (extended)
// -------------------------------------------------
void createWindowIfNeeded() {
  if (window)
    return;

  if (QGuiApplication::screens().isEmpty()) {
    qDebug() << "No screens yet, waiting...";
    return;
  }

  qDebug() << "Creating PRIMARY lockscreen window...";
  engine = new QQmlApplicationEngine;

  loadQml(engine, QUrl("qrc:/New/main.qml"));

  if (engine->rootObjects().isEmpty())
    return;

  window = qobject_cast<QQuickWindow *>(engine->rootObjects().first());
  if (!window)
    return;

  window->setScreen(QGuiApplication::primaryScreen());

  QObject::connect(window, &QObject::destroyed, []() {
    window = nullptr;
    layerWindow = nullptr;
    QTimer::singleShot(50, createWindowIfNeeded);
  });

  QTimer::singleShot(50, tryAttachWindow);

  // -------------------------------------------------
  // ADD: secondary screens (NO retries needed)
  // -------------------------------------------------
  for (QScreen *s : QGuiApplication::screens()) {

    if (s == QGuiApplication::primaryScreen())
      continue;

    auto *sec = new SecondaryWindow;
    sec->screen = s;
    sec->engine = new QQmlApplicationEngine;

    loadQml(sec->engine, QUrl("qrc:/New/main1.qml"));

    if (sec->engine->rootObjects().isEmpty()) {
      delete sec->engine;
      delete sec;
      continue;
    }

    sec->window =
        qobject_cast<QQuickWindow *>(sec->engine->rootObjects().first());

    if (!sec->window) {
      delete sec->engine;
      delete sec;
      continue;
    }

    sec->window->setScreen(s);
    setupLayerShell(sec->window, false);

    secondaryWindows << sec;
  }
}

// -------------------------------------------------
// Main
// -------------------------------------------------
int runLockscreen(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);

  QSharedMemory sharedMemory("Win8LockSingleton");
  if (!sharedMemory.create(1)) {
    qWarning() << "Another instance already running.";
    return 0;
  }

  createWindowIfNeeded();

  QObject::connect(&app, &QGuiApplication::screenAdded, [&](QScreen *) {
    QTimer::singleShot(100, createWindowIfNeeded);
  });

  QObject::connect(&app, &QGuiApplication::screenRemoved,
                   [&](QScreen *) { destroyLayerShell(); });

  QObject::connect(&app, &QGuiApplication::applicationStateChanged,
                   [&](Qt::ApplicationState state) {
                     if (state == Qt::ApplicationActive)
                       createWindowIfNeeded();
                   });

  return app.exec();
}

int main(int argc, char *argv[]) { return runLockscreen(argc, argv); }
