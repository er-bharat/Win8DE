#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSettings>
#include <QColor>
#include <QString>
#include <QFileDialog>
#include <QStandardPaths>
#include <QDir>
#include <QObject>

class SettingsManager : public QObject {
    Q_OBJECT

    // ---------------- WALLPAPER ----------------
    Q_PROPERTY(QString desktopWallpaper READ getDesktopWallpaper WRITE setDesktopWallpaper NOTIFY desktopWallpaperChanged)
    Q_PROPERTY(QString lockscreenWallpaper READ getLockscreenWallpaper WRITE setLockscreenWallpaper NOTIFY lockscreenWallpaperChanged)
    Q_PROPERTY(QString startWallpaper READ getStartWallpaper WRITE setStartWallpaper NOTIFY startWallpaperChanged)
    Q_PROPERTY(QString lastWallpaperFolder READ getLastWallpaperFolder WRITE setLastWallpaperFolder NOTIFY lastWallpaperFolderChanged)

    // ---------------- HOT CORNERS ----------------
    Q_PROPERTY(QString topLeftCorner READ getTopLeftCorner WRITE setTopLeftCorner NOTIFY hotCornersChanged)
    Q_PROPERTY(QString topRightCorner READ getTopRightCorner WRITE setTopRightCorner NOTIFY hotCornersChanged)
    Q_PROPERTY(QString bottomLeftCorner READ getBottomLeftCorner WRITE setBottomLeftCorner NOTIFY hotCornersChanged)
    Q_PROPERTY(QString bottomRightCorner READ getBottomRightCorner WRITE setBottomRightCorner NOTIFY hotCornersChanged)

public:
    explicit SettingsManager(QObject* parent = nullptr)
    : QObject(parent),
    settings(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/settings.ini", QSettings::IniFormat)
    {
        // Ensure Win8Corner config folder exists
        QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/Win8Corner";
        QDir().mkpath(configDir);
        hotCornerFile = configDir + "/hotcorners.ini";
    }

    // ---------------- WALLPAPER ----------------
    Q_INVOKABLE void setWallpaper(const QString& type, const QString& path) {
        settings.setValue("Wallpaper/" + type, path);
        if (type == "Desktop") emit desktopWallpaperChanged();
        else if (type == "Lockscreen") emit lockscreenWallpaperChanged();
        else if (type == "Start") emit startWallpaperChanged();
    }

    Q_INVOKABLE QString getWallpaper(const QString& type) {
        return settings.value("Wallpaper/" + type, "").toString();
    }

    QString getDesktopWallpaper() { return getWallpaper("Desktop"); }
    void setDesktopWallpaper(const QString &path) { setWallpaper("Desktop", path); }

    QString getLockscreenWallpaper() { return getWallpaper("Lockscreen"); }
    void setLockscreenWallpaper(const QString &path) { setWallpaper("Lockscreen", path); }

    QString getStartWallpaper() { return getWallpaper("Start"); }
    void setStartWallpaper(const QString &path) { setWallpaper("Start", path); }

    QString getLastWallpaperFolder() { return settings.value("Wallpaper/LastFolder", "").toString(); }
    void setLastWallpaperFolder(const QString& folder) {
        settings.setValue("Wallpaper/LastFolder", folder);
        emit lastWallpaperFolderChanged();
    }

    // ---------------- COLORS ----------------
    Q_INVOKABLE void setColor(const QString& type, const QString& colorStr) {
        settings.setValue("Colors/" + type, colorStr);
    }

    Q_INVOKABLE QString getColor(const QString& type) {
        return settings.value("Colors/" + type, "#ffffff").toString();
    }

    // ---------------- FILE DIALOGS ----------------
    Q_INVOKABLE QString openWallpaperFileDialog() {
        return QFileDialog::getOpenFileName(nullptr, "Select Wallpaper",
                                            QStandardPaths::writableLocation(QStandardPaths::PicturesLocation),
                                            "Images (*.png *.jpg *.jpeg *.bmp *.gif)");
    }

    Q_INVOKABLE QString openWallpaperFolderDialog(const QString &startFolder = "") {
        QString folder = QFileDialog::getExistingDirectory(nullptr, "Select Wallpaper Folder",
                                                           startFolder.isEmpty() ? QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) : startFolder);
        if (!folder.isEmpty()) setLastWallpaperFolder(folder);
        return folder;
    }

    Q_INVOKABLE QStringList listImagesInFolder(const QString& folderPath) {
        QStringList files;
        if (folderPath.isEmpty()) return files;

        QDir dir(folderPath);
        QStringList nameFilters = {"*.png", "*.jpg", "*.jpeg", "*.bmp", "*.gif"};
        files = dir.entryList(nameFilters, QDir::Files | QDir::NoSymLinks);
        for (int i = 0; i < files.size(); ++i) files[i] = dir.absoluteFilePath(files[i]);
        return files;
    }

    // ---------------- HOT CORNERS ----------------
    Q_INVOKABLE void setHotCorner(const QString& corner, const QString& command) {
        QSettings hotSettings(hotCornerFile, QSettings::IniFormat);
        hotSettings.setValue("Corners/" + corner, command);
        emit hotCornersChanged();
    }

    Q_INVOKABLE QString getHotCorner(const QString& corner) {
        QSettings hotSettings(hotCornerFile, QSettings::IniFormat);
        return hotSettings.value("Corners/" + corner, "").toString();
    }

    QString getTopLeftCorner() { return getHotCorner("TopLeft"); }
    void setTopLeftCorner(const QString& cmd) { setHotCorner("TopLeft", cmd); }

    QString getTopRightCorner() { return getHotCorner("TopRight"); }
    void setTopRightCorner(const QString& cmd) { setHotCorner("TopRight", cmd); }

    QString getBottomLeftCorner() { return getHotCorner("BottomLeft"); }
    void setBottomLeftCorner(const QString& cmd) { setHotCorner("BottomLeft", cmd); }

    QString getBottomRightCorner() { return getHotCorner("BottomRight"); }
    void setBottomRightCorner(const QString& cmd) { setHotCorner("BottomRight", cmd); }

signals:
    void desktopWallpaperChanged();
    void lockscreenWallpaperChanged();
    void startWallpaperChanged();
    void lastWallpaperFolderChanged();
    void hotCornersChanged();

private:
    QSettings settings;
    QString hotCornerFile;
};

#include "main.moc"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    SettingsManager settingsManager;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("SettingsManager", &settingsManager);
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    if (engine.rootObjects().isEmpty()) return -1;

    return app.exec();
}
