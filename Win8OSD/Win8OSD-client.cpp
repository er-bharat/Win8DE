#include <QCommandLineParser>
#include <QCoreApplication>
#include <QLocalSocket>
#include <QProcess>
#include <QRegularExpression>
#include <algorithm>

const QString socketName = "osd_instance_socket"; // ✅ No full path

void adjustVolumeAlsa(int deltaPercent)
{
    QString change = QString::number(std::abs(deltaPercent)) + "%";
    change += (deltaPercent > 0 ? "+" : "-");
    QProcess::execute("amixer", { "sset", "Master", change });
}

int getCurrentVolumeAlsa()
{
    QProcess proc;
    proc.start("amixer", { "sget", "Master" });
    proc.waitForFinished();
    QString output = proc.readAllStandardOutput();
    QRegularExpression re(R"(\[(\d+)%\])");
    QRegularExpressionMatch match = re.match(output);
    return match.hasMatch() ? match.captured(1).toInt() : 50;
}

bool getMuteStatusAlsa()
{
    QProcess proc;
    proc.start("amixer", { "get", "Master" });
    proc.waitForFinished();
    return proc.readAllStandardOutput().contains("[off]");
}

void toggleMute()
{
    QProcess::execute("amixer", { "sset", "Master", "toggle" });
}

void adjustBrightness(int deltaPercent)
{
    QProcess getProc, maxProc;
    getProc.start("brightnessctl", { "get" });
    getProc.waitForFinished();
    int current = getProc.readAllStandardOutput().trimmed().toInt();

    maxProc.start("brightnessctl", { "max" });
    maxProc.waitForFinished();
    int max = maxProc.readAllStandardOutput().trimmed().toInt();

    if (current <= 0 || max <= 0)
        return;

    int currentPercent = static_cast<int>((100.0 * current) / max);
    int newPercent = std::clamp(currentPercent + deltaPercent, 1, 100);
    QString value = QString::number(newPercent) + "%";
    QProcess::execute("brightnessctl", { "set", value });
}

int getCurrentBrightness()
{
    QProcess getProc, maxProc;
    getProc.start("brightnessctl", { "get" });
    getProc.waitForFinished();
    int current = getProc.readAllStandardOutput().trimmed().toInt();

    maxProc.start("brightnessctl", { "max" });
    maxProc.waitForFinished();
    int max = maxProc.readAllStandardOutput().trimmed().toInt();

    if (current > 0 && max > 0)
        return static_cast<int>((100.0 * current) / max);
    return 50;
}

int main(int argc, char* argv[])
{
    QCoreApplication app(argc, argv);
    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addOption({ "volup", "Increase volume" });
    parser.addOption({ "voldown", "Decrease volume" });
    parser.addOption({ "dispup", "Increase brightness" });
    parser.addOption({ "dispdown", "Decrease brightness" });
    parser.addOption({ "mute", "Toggle mute" });
    parser.process(app);

    QString mode;
    int value = 50;
    bool isMuted = getMuteStatusAlsa();

    if (parser.isSet("mute")) {
        toggleMute();
        isMuted = getMuteStatusAlsa();
        if (isMuted) {
            mode = "mute";
            value = 0;
        } else {
            mode = "volume";
            value = getCurrentVolumeAlsa();
        }
    } else if (parser.isSet("volup")) {
        if (isMuted)
            toggleMute();
        adjustVolumeAlsa(5);
        mode = "volume";
        value = getCurrentVolumeAlsa();
        isMuted = getMuteStatusAlsa();
    } else if (parser.isSet("voldown")) {
        if (isMuted)
            toggleMute();
        adjustVolumeAlsa(-5);
        mode = "volume";
        value = getCurrentVolumeAlsa();
        isMuted = getMuteStatusAlsa();
    } else if (parser.isSet("dispup")) {
        mode = "brightness";
        adjustBrightness(5);
        value = getCurrentBrightness();
    } else if (parser.isSet("dispdown")) {
        mode = "brightness";
        adjustBrightness(-5);
        value = getCurrentBrightness();
    } else {
        return 0;
    }

    QLocalSocket socket;
    socket.connectToServer(socketName);
    if (socket.waitForConnected(100)) {
        QString msg = mode + " " + QString::number(value) + " " + (isMuted ? "1" : "0");
        socket.write(msg.toUtf8());
        socket.flush();
        socket.waitForBytesWritten();
    } else {
        qWarning("OSD server is not running.");
    }

    return 0;
}
