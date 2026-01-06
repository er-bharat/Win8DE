#include <QCommandLineParser>
#include <QCoreApplication>
#include <QLocalSocket>
#include <QProcess>
#include <QRegularExpression>
#include <algorithm>

static constexpr auto socketName = "osd_instance_socket";
static constexpr int STEP = 5;

// ---------------- ALSA helpers ----------------

static int currentVolume()
{
    QProcess proc;
    proc.start("amixer", { "sget", "Master" });
    proc.waitForFinished();
    const QString out = proc.readAllStandardOutput();
    QRegularExpression re(R"(\[(\d+)%\])");
    auto m = re.match(out);
    return m.hasMatch() ? m.captured(1).toInt() : 50;
}

static bool isMuted()
{
    QProcess proc;
    proc.start("amixer", { "get", "Master" });
    proc.waitForFinished();
    return proc.readAllStandardOutput().contains("[off]");
}

static void changeVolume(int delta)
{
    const QString arg =
        QString::number(std::abs(delta)) + "%" + (delta > 0 ? "+" : "-");
    QProcess::execute("amixer", { "sset", "Master", arg });
}

static void toggleMute()
{
    QProcess::execute("amixer", { "sset", "Master", "toggle" });
}

// ---------------- Brightness helpers ----------------

static int brightnessPercent()
{
    QProcess get, max;
    get.start("brightnessctl", { "get" });
    get.waitForFinished();
    max.start("brightnessctl", { "max" });
    max.waitForFinished();
    
    int cur = get.readAllStandardOutput().trimmed().toInt();
    int m = max.readAllStandardOutput().trimmed().toInt();
    return (cur > 0 && m > 0) ? int(100.0 * cur / m) : 50;
}

static void changeBrightness(int delta)
{
    int cur = brightnessPercent();
    int next = std::clamp(cur + delta, 1, 100);
    QProcess::execute("brightnessctl", { "set", QString::number(next) + "%" });
}

// ---------------- Main ----------------

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    QCoreApplication::setApplicationName("win8osd");
    QCoreApplication::setApplicationVersion("1.0");
    
    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();
    parser.addOption({ "volup", "Increase volume" });
    parser.addOption({ "voldown", "Decrease volume" });
    parser.addOption({ "dispup", "Increase brightness" });
    parser.addOption({ "dispdown", "Decrease brightness" });
    parser.addOption({ "mute", "Toggle mute" });
    parser.process(app);
    
    QString mode;
    int value = 50;
    bool muted = isMuted();
    
    if (parser.isSet("mute")) {
        toggleMute();
        muted = !muted;
        mode = muted ? "mute" : "volume";
        value = muted ? 0 : currentVolume();
        
    } else if (parser.isSet("volup") || parser.isSet("voldown")) {
        if (muted) toggleMute();
        changeVolume(parser.isSet("volup") ? STEP : -STEP);
        muted = false;
        mode = "volume";
        value = currentVolume();
        
    } else if (parser.isSet("dispup") || parser.isSet("dispdown")) {
        changeBrightness(parser.isSet("dispup") ? STEP : -STEP);
        mode = "brightness";
        value = brightnessPercent();
        
    } else {
        parser.showHelp();
    }
    
    // ---------------- IPC ----------------
    
    QLocalSocket socket;
    socket.connectToServer(socketName);
    
    if (socket.waitForConnected(50)) {
        const QString msg =
        QString("%1 %2 %3\n")
        .arg(mode)
        .arg(value)
        .arg(muted ? 1 : 0);
        
        socket.write(msg.toUtf8());
        socket.waitForBytesWritten(50);
    }
    
    return 0;
}
