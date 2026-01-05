#include "wlr-foreign-toplevel-management-unstable-v1-client-protocol.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QLocalServer>
#include <QLocalSocket>
#include <QSettings>
#include <QSocketNotifier>
#include <QStandardPaths>
#include <QStringList>

#include <cstring>
#include <iostream>
#include <map>

#include <wayland-client.h>

extern "C" {
extern const struct wl_interface zwlr_foreign_toplevel_manager_v1_interface;
extern const struct wl_interface zwlr_foreign_toplevel_handle_v1_interface;
}

// ------------------------------------------------------------
// Globals
// ------------------------------------------------------------
struct wl_display *display = nullptr;
struct wl_registry *registry = nullptr;
struct zwlr_foreign_toplevel_manager_v1 *toplevel_manager = nullptr;
struct wl_seat *seat = nullptr;

bool dirty = false;


// ------------------------------------------------------------
// Window tracking
// ------------------------------------------------------------
struct WindowInfo {
  std::string title;
  std::string app_id;
  std::string icon_name; // new
  bool focused = false;
  bool minimized = false;
  bool maximized = false;
};

std::map<zwlr_foreign_toplevel_handle_v1 *, WindowInfo> windows;

// ------------------------------------------------------------
// Helper: find icon from app_id
// ------------------------------------------------------------
QString find_icon_for_app(const std::string &app_id) {
  if (app_id.empty())
    return "";

  QString app = QString::fromStdString(app_id);

  // extract short name
  QString shortName = app;
  int lastDot = app.lastIndexOf('.');
  if (lastDot >= 0)
    shortName = app.mid(lastDot + 1);

  QStringList dirs = {"/usr/share/applications",
                      "/usr/local/share/applications",
                      QDir::homePath() + "/.local/share/applications"};

  QString fallbackIcon;

  for (const QString &dir : dirs) {
    QDirIterator it(dir, QStringList() << "*.desktop", QDir::Files);
    while (it.hasNext()) {
      it.next();
      QSettings desktop(it.filePath(), QSettings::IniFormat);
      desktop.beginGroup("Desktop Entry");

      QString name = desktop.value("Name").toString();
      QString wmclass = desktop.value("StartupWMClass").toString();
      QString exec = desktop.value("Exec").toString();
      QString icon = desktop.value("Icon").toString();
      QString onlyShowIn = desktop.value("OnlyShowIn").toString();

      // ---- NEW: skip desktop handlers / services ----
      bool isDesktopHandler =
          exec.contains("--desktop", Qt::CaseInsensitive) ||
          name.compare("Desktop", Qt::CaseInsensitive) == 0 ||
          !onlyShowIn.isEmpty();

      if (isDesktopHandler) {
        desktop.endGroup();
        continue;
      }
      // ----------------------------------------------

      // exact match first
      if (name.compare(shortName, Qt::CaseInsensitive) == 0 ||
          wmclass.compare(shortName, Qt::CaseInsensitive) == 0 ||
          exec.compare(shortName, Qt::CaseInsensitive) == 0) {
        desktop.endGroup();
        return icon;
      }

      // partial match fallback
      if ((name.contains(shortName, Qt::CaseInsensitive) ||
           wmclass.contains(shortName, Qt::CaseInsensitive) ||
           exec.contains(shortName, Qt::CaseInsensitive)) &&
          fallbackIcon.isEmpty()) {
        fallbackIcon = icon;
      }

      desktop.endGroup();
    }
  }

  if (!fallbackIcon.isEmpty())
    return fallbackIcon;

  return shortName;
}

// ------------------------------------------------------------
// INI writer
// ------------------------------------------------------------
void write_all_windows_to_ini() {
  QString configDir =
      QDir::homePath() + "/.config/" + QCoreApplication::applicationName();
  QDir().mkpath(configDir); // create directory if it doesn't exist
  QString path = configDir + "/windows.ini";

  QSettings settings(path, QSettings::IniFormat);
  settings.clear();

  int index = 1;
  for (auto &[handle, win] : windows) {
    if (win.title.empty() || win.app_id.empty())
      continue;

    // Fill icon_name if empty
    if (win.icon_name.empty()) {
      win.icon_name = find_icon_for_app(win.app_id).toStdString();
    }

    settings.beginGroup(QString::number(index++));
    settings.setValue("Title", QString::fromStdString(win.title));
    settings.setValue("AppID", QString::fromStdString(win.app_id));
    settings.setValue("Icon", QString::fromStdString(win.icon_name)); // new
    settings.setValue("Focused", win.focused);
    settings.setValue("Minimized", win.minimized);
    settings.setValue("Maximized", win.maximized);
    settings.endGroup();
  }

  settings.sync();
}
void activate_only(const QString &title) {
  zwlr_foreign_toplevel_handle_v1 *targetHandle = nullptr;

  // First pass: find target
  for (auto &[handle, win] : windows) {
    if (QString::fromStdString(win.title) == title) {
      targetHandle = handle;
      break;
    }
  }

  if (!targetHandle)
    return;

  // Second pass: minimize everything else
  for (auto &[handle, win] : windows) {
    if (handle != targetHandle) {
      zwlr_foreign_toplevel_handle_v1_set_minimized(handle);
    }
  }

  // Activate target
  if (seat)
    zwlr_foreign_toplevel_handle_v1_activate(targetHandle, seat);

  wl_display_flush(display);
}

// ------------------------------------------------------------
// Command handling
// ------------------------------------------------------------
void handle_command(const QString &cmd) {
  // Trim whitespace
  QString trimmedCmd = cmd.trimmed();
  if (trimmedCmd.isEmpty())
    return;

  // Split into exactly 2 parts: action and title
  int firstSpace = trimmedCmd.indexOf(' ');
  if (firstSpace <= 0 || firstSpace == trimmedCmd.length() - 1)
    return;

  QString actionStr = trimmedCmd.left(firstSpace).toLower();
  QString title = trimmedCmd.mid(firstSpace + 1).trimmed();
  if (title.isEmpty())
    return;

  // Map of allowed actions
  enum class Action { Activate, Minimize, Maximize, Unmaximize, Close, ActivateOnly };
  static const std::map<QString, Action> actionMap = {
      {"activate", Action::Activate},
      {"activate-only", Action::ActivateOnly},
      {"minimize", Action::Minimize},
      {"maximize", Action::Maximize},
      {"unmaximize", Action::Unmaximize},
      {"close", Action::Close}};

  auto it = actionMap.find(actionStr);
  if (it == actionMap.end())
    return; // unknown action

  // Find the window
  zwlr_foreign_toplevel_handle_v1 *targetHandle = nullptr;
  for (auto &[handle, win] : windows) {
    if (QString::fromStdString(win.title) == title) {
      targetHandle = handle;
      break;
    }
  }
  if (!targetHandle)
    return; // no window found

  // Execute action
  switch (it->second) {
  case Action::Activate:
    if (seat)
      zwlr_foreign_toplevel_handle_v1_activate(targetHandle, seat);
    break;
  case Action::Minimize:
    zwlr_foreign_toplevel_handle_v1_set_minimized(targetHandle);
    break;
  case Action::Maximize:
    zwlr_foreign_toplevel_handle_v1_set_maximized(targetHandle);
    break;
  case Action::Unmaximize:
    zwlr_foreign_toplevel_handle_v1_unset_maximized(targetHandle);
    break;
  case Action::Close:
    zwlr_foreign_toplevel_handle_v1_close(targetHandle);
    break;
  case Action::ActivateOnly:
    activate_only(title);
    return; // already flushed

  }

  wl_display_flush(display);
}

// ------------------------------------------------------------
// Wayland listeners
// ------------------------------------------------------------
static void handle_title(void *, zwlr_foreign_toplevel_handle_v1 *handle,
                         const char *title) {
  windows[handle].title = title ? title : "";
  dirty = true;
}

static void handle_app_id(void *, zwlr_foreign_toplevel_handle_v1 *handle,
                          const char *app_id) {
  windows[handle].app_id = app_id ? app_id : "";
  dirty = true;
}

static void handle_state(void *, zwlr_foreign_toplevel_handle_v1 *handle,
                         wl_array *state) {
  auto &win = windows[handle];
  win.focused = win.minimized = win.maximized = false;

  char *end = (char *)state->data + state->size;
  for (char *ptr = (char *)state->data; ptr < end; ptr += sizeof(uint32_t)) {
    uint32_t s = *(uint32_t *)ptr;
    if (s == ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_ACTIVATED)
      win.focused = true;
    else if (s == ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_MINIMIZED)
      win.minimized = true;
    else if (s == ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_MAXIMIZED)
      win.maximized = true;
  }

  dirty = true;
}

static void handle_done(void *, zwlr_foreign_toplevel_handle_v1 *) {
  dirty = true;
}

static void handle_closed(void *, zwlr_foreign_toplevel_handle_v1 *handle) {
  windows.erase(handle);
  dirty = true;
}

static void handle_parent(void *, zwlr_foreign_toplevel_handle_v1 *,
                          zwlr_foreign_toplevel_handle_v1 *) {}

static const zwlr_foreign_toplevel_handle_v1_listener toplevel_handle_listener =
    {.title = handle_title,
     .app_id = handle_app_id,
     .output_enter = nullptr,
     .output_leave = nullptr,
     .state = handle_state,
     .done = handle_done,
     .closed = handle_closed,
     .parent = handle_parent};

// ------------------------------------------------------------
// Manager listener
// ------------------------------------------------------------
static void manager_handle_toplevel(void *, zwlr_foreign_toplevel_manager_v1 *,
                                    zwlr_foreign_toplevel_handle_v1 *handle) {
  windows.emplace(handle, WindowInfo());
  zwlr_foreign_toplevel_handle_v1_add_listener(
      handle, &toplevel_handle_listener, nullptr);
  dirty = true;
}

static const zwlr_foreign_toplevel_manager_v1_listener manager_listener = {
    .toplevel = manager_handle_toplevel, .finished = nullptr};

// ------------------------------------------------------------
// Registry
// ------------------------------------------------------------
static void handle_global(void *, wl_registry *registry, uint32_t name,
                          const char *interface, uint32_t) {
  if (strcmp(interface, zwlr_foreign_toplevel_manager_v1_interface.name) == 0) {
    toplevel_manager =
        static_cast<zwlr_foreign_toplevel_manager_v1 *>(wl_registry_bind(
            registry, name, &zwlr_foreign_toplevel_manager_v1_interface, 3));
  } else if (strcmp(interface, "wl_seat") == 0) {
    seat = static_cast<wl_seat *>(
        wl_registry_bind(registry, name, &wl_seat_interface, 1));
  }
}

static const wl_registry_listener registry_listener = {
    .global = handle_global, .global_remove = nullptr};

// ------------------------------------------------------------
// MAIN
// ------------------------------------------------------------
int main(int argc, char **argv) {
  QCoreApplication app(argc, argv);
  QCoreApplication::setApplicationName(QFileInfo(argv[0]).baseName());
  
  const QString socketPath =
  QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
  + "/" + QCoreApplication::applicationName()
  + "/" + QCoreApplication::applicationName() + ".sock";
  
  // --------------------------------------------------------
  // HELP MESSAGE
  // --------------------------------------------------------
  if (argc >= 2) {
    QString flag = argv[1];
    if (flag == "-h" || flag == "--help") {
      std::cout
          << "Usage:\n"
          << "  " << argv[0] << " [COMMAND] [WINDOW_TITLE]\n\n"
          << "Commands:\n"
          << "  --activate TITLE     Activate the window with the given TITLE\n"
          << "  --activate-only TITLE  Activate TITLE and minimize all other windows\n"
          << "  --minimize TITLE     Minimize the window with the given TITLE\n"
          << "  --maximize TITLE     Maximize the window with the given TITLE\n"
          << "  --unmaximize TITLE   Unmaximize the window with the given "
             "TITLE\n"
          << "  --close TITLE        Close the window with the given TITLE\n\n"
          << "Run without arguments to start the daemon.\n";
      return 0;
    }
  }

  // --------------------------------------------------------
  // CLIENT MODE
  // --------------------------------------------------------
  if (argc >= 3) {
    QString flag = argv[1];
    QString title = argv[2];

    QString cmd;
    if (flag == "--activate")
      cmd = "activate " + title;
    if (flag == "--minimize")
      cmd = "minimize " + title;
    if (flag == "--maximize")
      cmd = "maximize " + title;
    if (flag == "--unmaximize")
      cmd = "unmaximize " + title;
    if (flag == "--close")
      cmd = "close " + title;
    if (flag == "--activate-only")
      cmd = "activate-only " + title;

    if (!cmd.isEmpty()) {
      QLocalSocket sock;
      sock.connectToServer(socketPath);
      if (!sock.waitForConnected(500)) {
        std::cerr << "Failed to connect to socket: "
        << socketPath.toStdString() << std::endl;
        return 1;
      }
      
      sock.write(cmd.toUtf8());
      sock.waitForBytesWritten();
      
      return 0;
    }
  }

  // --------------------------------------------------------
  // DAEMON MODE
  // --------------------------------------------------------
  display = wl_display_connect(nullptr);
  if (!display) {
    std::cerr << "Failed to connect to Wayland\n";
    return 1;
  }

  registry = wl_display_get_registry(display);
  wl_registry_add_listener(registry, &registry_listener, nullptr);
  wl_display_roundtrip(display);

  zwlr_foreign_toplevel_manager_v1_add_listener(toplevel_manager,
                                                &manager_listener, nullptr);
  wl_display_roundtrip(display);

  // --------------------------------------------------------
  // Wayland FD → Qt
  // --------------------------------------------------------
  int wl_fd = wl_display_get_fd(display);
  QSocketNotifier wlNotifier(wl_fd, QSocketNotifier::Read, &app);

  QObject::connect(&wlNotifier, &QSocketNotifier::activated, [&]() {
    wl_display_dispatch(display);
    if (dirty) {
      write_all_windows_to_ini();
      dirty = false;
    }
  });

  // --------------------------------------------------------
  // Command socket
  // --------------------------------------------------------
  {
    QFile::remove(socketPath);
    
    QDir dir(QFileInfo(socketPath).absolutePath());
    if (!dir.exists()) {
      dir.mkpath(".");
    }
    
    static QLocalServer server;
    
    if (!server.listen(socketPath)) {
      std::cerr << "Failed to listen on socket: "
      << server.errorString().toStdString() << std::endl;
      return 1;
    }
    
    QObject::connect(&server, &QLocalServer::newConnection, [&]() {
      QLocalSocket *client = server.nextPendingConnection();
      
      QObject::connect(client, &QLocalSocket::readyRead, [client]() {
        handle_command(QString::fromUtf8(client->readAll()).trimmed());
        client->disconnectFromServer();
        client->deleteLater();
      });
    });
  }
  

  return app.exec();
}
