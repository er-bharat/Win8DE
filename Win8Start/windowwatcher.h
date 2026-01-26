#pragma once

#include <QObject>
#include <QString>
#include <QMap>
#include <QDebug>

extern "C" {
    #include "wlr-foreign-toplevel-management-unstable-v1-client-protocol.h"
    #include <wayland-client.h>
}

// Structure to hold window info
struct WindowInfo {
    QString title;
};

class WindowWatcher : public QObject {
    Q_OBJECT
public:
    explicit WindowWatcher(QObject *parent = nullptr);
    ~WindowWatcher();
    
    void start();  // Start monitoring windows
    
signals:
    void windowAdded(const QString &title);
    void windowRemoved(const QString &title);
    
private:
    wl_display *display = nullptr;
    wl_registry *registry = nullptr;
    zwlr_foreign_toplevel_manager_v1 *toplevel_manager = nullptr;
    
    QMap<zwlr_foreign_toplevel_handle_v1*, WindowInfo> windows;
    
    // -----------------------------
    // Wayland handlers
    // -----------------------------
    static void handleTitle(void *data, zwlr_foreign_toplevel_handle_v1 *handle, const char *title);
    static void handleAppId(void *, zwlr_foreign_toplevel_handle_v1 *, const char *) {}
    static void handleOutputEnter(void *, zwlr_foreign_toplevel_handle_v1 *, wl_output *) {}
    static void handleOutputLeave(void *, zwlr_foreign_toplevel_handle_v1 *, wl_output *) {}
    static void handleState(void *, zwlr_foreign_toplevel_handle_v1 *, wl_array *) {}
    static void handleDone(void *, zwlr_foreign_toplevel_handle_v1 *) {}
    static void handleClosed(void *data, zwlr_foreign_toplevel_handle_v1 *handle);
    static void handleParent(void *, zwlr_foreign_toplevel_handle_v1 *, zwlr_foreign_toplevel_handle_v1 *) {}
    
    static void managerHandleToplevel(void *data, zwlr_foreign_toplevel_manager_v1 *, zwlr_foreign_toplevel_handle_v1 *handle);
    static void handleGlobal(void *data, wl_registry *registry, uint32_t name, const char *interface, uint32_t version);
    
    // Listeners
    static const zwlr_foreign_toplevel_handle_v1_listener toplevel_handle_listener;
    static const zwlr_foreign_toplevel_manager_v1_listener manager_listener;
    static const wl_registry_listener registry_listener;
};
