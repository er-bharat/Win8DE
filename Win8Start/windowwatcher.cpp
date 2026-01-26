#include "windowwatcher.h"
#include <QSocketNotifier>
#include <QDebug>
#include <cstring>

// -----------------------------
// Static listeners
// -----------------------------
const zwlr_foreign_toplevel_handle_v1_listener WindowWatcher::toplevel_handle_listener = {
    .title = handleTitle,
    .app_id = handleAppId,
    .output_enter = handleOutputEnter,
    .output_leave = handleOutputLeave,
    .state = handleState,
    .done = handleDone,
    .closed = handleClosed,
    .parent = handleParent
};

const zwlr_foreign_toplevel_manager_v1_listener WindowWatcher::manager_listener = {
    .toplevel = managerHandleToplevel,
    .finished = nullptr
};

const wl_registry_listener WindowWatcher::registry_listener = {
    .global = handleGlobal,
    .global_remove = nullptr
};

// -----------------------------
// Constructor / Destructor
// -----------------------------
WindowWatcher::WindowWatcher(QObject *parent)
: QObject(parent) {}

WindowWatcher::~WindowWatcher() {
    if (display) {
        wl_display_disconnect(display);
    }
}

// -----------------------------
// Public start method
// -----------------------------
void WindowWatcher::start() {
    display = wl_display_connect(nullptr);
    if (!display) {
        qWarning() << "Failed to connect to Wayland";
        return;
    }
    
    registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, this);
    wl_display_roundtrip(display);
    
    if (!toplevel_manager) {
        qWarning() << "Failed to bind to zwlr_foreign_toplevel_manager_v1";
        return;
    }
    
    zwlr_foreign_toplevel_manager_v1_add_listener(
        toplevel_manager,
        &manager_listener,
        this
    );
    wl_display_roundtrip(display);
    
    // Use QSocketNotifier to watch the Wayland FD
    int fd = wl_display_get_fd(display);
    QSocketNotifier *notifier =
    new QSocketNotifier(fd, QSocketNotifier::Read, this);
    
    connect(notifier, &QSocketNotifier::activated, this, [this]() {
        if (wl_display_prepare_read(display) != 0) {
            wl_display_dispatch_pending(display);
            return;
        }
        
        wl_display_flush(display);
        wl_display_read_events(display);
        wl_display_dispatch_pending(display);
    });
    
    qInfo() << "WindowWatcher started, monitoring Wayland windows...";
}

// -----------------------------
// Wayland callbacks
// -----------------------------
void WindowWatcher::managerHandleToplevel(
    void *data,
    zwlr_foreign_toplevel_manager_v1 *,
    zwlr_foreign_toplevel_handle_v1 *handle)
{
    auto *self = static_cast<WindowWatcher*>(data);
    
    self->windows.insert(handle, WindowInfo());
    
    // 🔔 Window launched
    qInfo() << "[Wayland] New window launched (handle =" << handle << ")";
    
    zwlr_foreign_toplevel_handle_v1_add_listener(
        handle,
        &toplevel_handle_listener,
        self
    );
}

void WindowWatcher::handleTitle(
    void *data,
    zwlr_foreign_toplevel_handle_v1 *handle,
    const char *title)
{
    auto *self = static_cast<WindowWatcher*>(data);
    if (!title) return;
    
    auto &info = self->windows[handle];
    
    // 🔔 First title = window ready
    if (info.title.isEmpty()) {
        qInfo() << "[Wayland] Window ready:" << title;
    }
    
    info.title = QString::fromUtf8(title);
    emit self->windowAdded(info.title);
}

void WindowWatcher::handleClosed(
    void *data,
    zwlr_foreign_toplevel_handle_v1 *handle)
{
    auto *self = static_cast<WindowWatcher*>(data);
    
    if (self->windows.contains(handle)) {
        qInfo() << "[Wayland] Window closed:"
        << self->windows[handle].title;
        
        emit self->windowRemoved(self->windows[handle].title);
        self->windows.remove(handle);
    }
}

void WindowWatcher::handleGlobal(
    void *data,
    wl_registry *,
    uint32_t name,
    const char *interface,
    uint32_t version)
{
    auto *self = static_cast<WindowWatcher*>(data);
    
    if (strcmp(
        interface,
        zwlr_foreign_toplevel_manager_v1_interface.name
    ) == 0)
    {
        self->toplevel_manager =
        static_cast<zwlr_foreign_toplevel_manager_v1*>(
            wl_registry_bind(
                self->registry,
                name,
                &zwlr_foreign_toplevel_manager_v1_interface,
                version
            )
        );
    }
}
