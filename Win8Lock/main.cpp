#include "lockmanager.h"

#include <LayerShellQt/window.h>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSettings>
#include <QSharedMemory>
#include <QStandardPaths>
#include <QTimer>

QQuickWindow *window = nullptr;
LayerShellQt::Window *layerWindow = nullptr;
QQmlApplicationEngine *engine = nullptr;

// ----- Setup LayerShell on a valid QQuickWindow -----
void setupLayerShell(QQuickWindow *w) {
  if (!w) return;
  
  layerWindow = LayerShellQt::Window::get(w);
  layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);
  layerWindow->setScope("lockscreen");
  layerWindow->setKeyboardInteractivity(
    LayerShellQt::Window::KeyboardInteractivityExclusive);
  layerWindow->setAnchors({
    LayerShellQt::Window::AnchorTop,
    LayerShellQt::Window::AnchorBottom,
    LayerShellQt::Window::AnchorLeft,
    LayerShellQt::Window::AnchorRight
  });
  layerWindow->setExclusiveZone(-1);
  
  w->setFlags(Qt::Window | Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
  w->show();
}

// ----- Destroy LayerShell safely -----
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
}

// ----- Try attaching LayerShell only when window has a real screen -----
void tryAttachWindow() {
  if (!window) return;
  
  QScreen *s = window->screen();
  if (!s || s->geometry().width() < 2 || s->geometry().height() < 2) {
    qDebug() << "Window not on a valid screen, retrying...";
    QTimer::singleShot(500, tryAttachWindow);
    return;
  }
  
  qDebug() << "Attaching LayerShell to screen:" << s->name();
  setupLayerShell(window);
}

// ----- Load QML and set context properties -----
void loadQml() {
  if (!engine) return;
  
  static LockManager lockManager;
  engine->rootContext()->setContextProperty("lockManager", &lockManager);
  
  QString userName = qgetenv("USER");
  if (userName.isEmpty()) userName = qgetenv("USERNAME");
  engine->rootContext()->setContextProperty("systemUsername", userName);
  
  QString avatarPath = QString("/var/lib/AccountsService/icons/%1").arg(userName);
  QString avatarUrl = QFileInfo::exists(avatarPath)
  ? QUrl::fromLocalFile(avatarPath).toString()
  : "qrc:/images/default-avatar.png";
  engine->rootContext()->setContextProperty("userAvatar", avatarUrl);
  
  QString win8SettingsPath = QDir(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation))
  .filePath("Win8Settings/settings.ini");
  QSettings win8Settings(win8SettingsPath, QSettings::IniFormat);
  
  QVariantMap Win8Colors;
  win8Settings.beginGroup("Colors");
  Win8Colors["background"] = win8Settings.value("Background", "#000000").toString();
  Win8Colors["tile"] = win8Settings.value("Tile", "#ffffff").toString();
  Win8Colors["tileHighlight"] = win8Settings.value("TileHighlight", "#ff0000").toString();
  win8Settings.endGroup();
  engine->rootContext()->setContextProperty("Win8Colors", QVariant::fromValue(Win8Colors));
  
  win8Settings.beginGroup("Wallpaper");
  QString lockscreenPath = win8Settings.value("Lockscreen").toString();
  win8Settings.endGroup();
  QString lockscreenWallpaper = (QFileInfo::exists(lockscreenPath))
  ? QUrl::fromLocalFile(lockscreenPath).toString()
  : "";
  engine->rootContext()->setContextProperty("wallpaperPath", lockscreenWallpaper);
  
  engine->load(QUrl("qrc:/New/main.qml"));
}

// ----- Create window safely only if a real screen exists -----
void createWindowIfNeeded() {
  if (window) return; // already exists
  
  if (QGuiApplication::screens().isEmpty()) {
    // Wait until a screen is available
    qDebug() << "No screens yet, waiting for screenAdded...";
    return;
  }
  
  qDebug() << "Creating new lockscreen window...";
  if (engine) delete engine;
  engine = new QQmlApplicationEngine;
  
  loadQml();
  if (engine->rootObjects().isEmpty()) {
    qWarning() << "Failed to load QML!";
    return;
  }
  
  window = qobject_cast<QQuickWindow *>(engine->rootObjects().first());
  if (!window) {
    qWarning() << "Root object is not a QQuickWindow!";
    return;
  }
  
  QObject::connect(window, &QObject::destroyed, []() {
    qDebug() << "QQuickWindow destroyed";
    window = nullptr;
    layerWindow = nullptr;
    // Attempt reattachment later if screens exist
    QTimer::singleShot(50, createWindowIfNeeded);
  });
  
  QTimer::singleShot(50, tryAttachWindow);
}

// ----- Main lockscreen runner -----
int runLockscreen(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);
  
  // Single instance check
  QSharedMemory sharedMemory("Win8LockSingleton");
  if (!sharedMemory.create(1)) {
    qWarning() << "Another instance is already running.";
    return 0;
  }
  
  // Initial window creation if screens exist
  createWindowIfNeeded();
  
  // React to Wayland screen changes
  QObject::connect(&app, &QGuiApplication::screenAdded, [&](QScreen *) {
    QTimer::singleShot(100, createWindowIfNeeded);
  });
  QObject::connect(&app, &QGuiApplication::screenRemoved, [&](QScreen *) {
    destroyLayerShell();
  });
  
  // Handle TTY / application state changes
  QObject::connect(&app, &QGuiApplication::applicationStateChanged, [&](Qt::ApplicationState state){
    if (state == Qt::ApplicationActive) {
      createWindowIfNeeded();
    }
  });
  
  return app.exec();
}

int main(int argc, char *argv[]) {
  return runLockscreen(argc, argv);
}
