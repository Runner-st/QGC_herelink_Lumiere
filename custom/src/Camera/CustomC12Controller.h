/****************************************************************************
 *
 * Custom C12 Camera Controller for Skydroid C12
 * Sends UDP commands to control camera PTZ and zoom
 *
 ****************************************************************************/

#pragma once

#include <QObject>
#include <QUdpSocket>
#include <QHostAddress>

class CustomC12Controller : public QObject
{
    Q_OBJECT

public:
    explicit CustomC12Controller(QObject *parent = nullptr);
    ~CustomC12Controller();

    // Camera control methods callable from QML
    Q_INVOKABLE void centerCamera();
    Q_INVOKABLE void centerTiltOnly();
    Q_INVOKABLE void zoomIn();
    Q_INVOKABLE void zoomOut();
    Q_INVOKABLE void cyclePalette();
    Q_INVOKABLE void sendVertCommand();
    Q_INVOKABLE void sendCustomCommand(const QString& command);

    // Camera directional movement
    Q_INVOKABLE void moveRight();
    Q_INVOKABLE void moveLeft();
    Q_INVOKABLE void moveUp();
    Q_INVOKABLE void moveDown();

private:
    void sendCommand(const QString& command);

    QUdpSocket*     _udpSocket;
    QHostAddress    _cameraAddress;
    quint16         _cameraPort;
    int             _currentPaletteIndex;
};
