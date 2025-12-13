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

void CustomC12Controller::sendCustomCommand(const QString& command)
{
    qDebug() << "[C12] Custom Command:" << command;
    sendCommand(command);
}
