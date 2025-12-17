/****************************************************************************
 *
 * Custom C12 Camera Controller Implementation
 *
 ****************************************************************************/

#include "CustomC12Controller.h"
#include <QDebug>

CustomC12Controller::CustomC12Controller(QObject *parent)
    : QObject(parent)
    , _udpSocket(new QUdpSocket(this))
    , _cameraAddress("192.168.144.108")
    , _cameraPort(5000)
    , _currentPaletteIndex(0)
{
    qDebug() << "=== C12 Camera Controller Initialized ===";
    qDebug() << "Target Address:" << _cameraAddress.toString();
    qDebug() << "Target Port:" << _cameraPort;
}

CustomC12Controller::~CustomC12Controller()
{
    if (_udpSocket) {
        _udpSocket->close();
    }
    qDebug() << "=== C12 Camera Controller Destroyed ===";
}

void CustomC12Controller::sendCommand(const QString& command)
{
    QByteArray data = command.toUtf8();
    qint64 sent = _udpSocket->writeDatagram(data, _cameraAddress, _cameraPort);
    
    if (sent == -1) {
        qWarning() << "[C12 ERROR] Failed to send UDP command:" << _udpSocket->errorString();
    } else {
        qDebug() << "[C12 CMD] Sent:" << command << "(" << sent << "bytes)";
    }
}

void CustomC12Controller::centerCamera()
{
    qDebug() << "[C12] Center Camera (Pan + Tilt)";
    sendCommand("#TPUG2wPTZ056F");
}

void CustomC12Controller::centerTiltOnly()
{
    qDebug() << "[C12] Center Tilt Only";
    sendCommand("#TPUG2wPTZ026C");
}

void CustomC12Controller::zoomIn()
{
    qDebug() << "[C12] Zoom In";
    sendCommand("#TPUD2wDZM0A65");
}

void CustomC12Controller::zoomOut()
{
    qDebug() << "[C12] Zoom Out";
    sendCommand("#TPUD2wDZM0B66");
}

void CustomC12Controller::cyclePalette()
{
    // Array of palette commands
    const QString paletteCommands[] = {
        "#TPUD2wIMG0147",  // WHITE_HOT
        "#TPUD2wIMG0B58",  // BLACK_HOT
        "#TPUD2wIMG0349",  // SEPIA
        "#TPUD2wIMG044A",  // IRONBOW
        "#TPUD2wIMG054B",  // RAINBOW
        "#TPUD2wIMG064C",  // NIGHT
        "#TPUD2wIMG084E",  // RED_HOT
        "#TPUD2wIMG094F",  // JUNGLE
        "#TPUD2wIMG0A57",  // MEDICAL
        "#TPUD2wIMG0C59"   // GLORY_HOT
    };

    const QString paletteNames[] = {
        "WHITE_HOT",
        "BLACK_HOT",
        "SEPIA",
        "IRONBOW",
        "RAINBOW",
        "NIGHT",
        "RED_HOT",
        "JUNGLE",
        "MEDICAL",
        "GLORY_HOT"
    };

    const int paletteCount = 10;

    // Send current palette command
    qDebug() << "[C12] Cycle Palette to:" << paletteNames[_currentPaletteIndex];
    sendCommand(paletteCommands[_currentPaletteIndex]);

    // Move to next palette
    _currentPaletteIndex = (_currentPaletteIndex + 1) % paletteCount;
}

void CustomC12Controller::sendVertCommand()
{
    qDebug() << "[C12] Send Vert Command";
    sendCommand("#TPUG6wGAY00001012");
}

void CustomC12Controller::sendCustomCommand(const QString& command)
{
    qDebug() << "[C12] Custom Command:" << command;
    sendCommand(command);
}
