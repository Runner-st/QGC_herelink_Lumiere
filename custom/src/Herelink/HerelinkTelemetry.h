/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QObject>
#include <QString>
#include <QTimer>

/// Provides access to Herelink radio telemetry from HerelinkSettings notification.
/// On Android, receives data from HerelinkNotificationService (running in separate process)
/// via broadcast Intent -> QGCActivity -> JNI.
class HerelinkTelemetry : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool    available                READ available                NOTIFY availableChanged)
    Q_PROPERTY(QString pairState                READ pairState                NOTIFY telemetryChanged)
    Q_PROPERTY(int     controllerSignalMain     READ controllerSignalMain     NOTIFY telemetryChanged)
    Q_PROPERTY(int     controllerSignalSecondary READ controllerSignalSecondary NOTIFY telemetryChanged)
    Q_PROPERTY(int     airSignalMain            READ airSignalMain            NOTIFY telemetryChanged)
    Q_PROPERTY(int     airSignalSecondary       READ airSignalSecondary       NOTIFY telemetryChanged)
    Q_PROPERTY(int     uplinkRate               READ uplinkRate               NOTIFY telemetryChanged)
    Q_PROPERTY(int     uplinkBandwidth          READ uplinkBandwidth          NOTIFY telemetryChanged)
    Q_PROPERTY(int     flyDistance              READ flyDistance              NOTIFY telemetryChanged)

public:
    explicit HerelinkTelemetry(QObject *parent = nullptr);
    ~HerelinkTelemetry();

    static HerelinkTelemetry* instance();

    bool    available()                const { return _available; }
    QString pairState()                const { return _pairState; }
    int     controllerSignalMain()     const { return _controllerSignalMain; }
    int     controllerSignalSecondary() const { return _controllerSignalSecondary; }
    int     airSignalMain()            const { return _airSignalMain; }
    int     airSignalSecondary()       const { return _airSignalSecondary; }
    int     uplinkRate()               const { return _uplinkRate; }
    int     uplinkBandwidth()          const { return _uplinkBandwidth; }
    int     flyDistance()              const { return _flyDistance; }

    Q_INVOKABLE void updateTelemetry(
        const QString& pairState,
        int controllerSignalMain,
        int controllerSignalSecondary,
        int airSignalMain,
        int airSignalSecondary,
        int uplinkRate,
        int uplinkBandwidth,
        int flyDistance
    );

signals:
    void availableChanged();
    void telemetryChanged();

private slots:
    void _staleTimeout();

private:
    static HerelinkTelemetry* _instance;

    QTimer  _staleTimer;
    bool    _available                 = false;
    QString _pairState                 = "Unknown";
    int     _controllerSignalMain      = 0;
    int     _controllerSignalSecondary = 0;
    int     _airSignalMain             = 0;
    int     _airSignalSecondary        = 0;
    int     _uplinkRate                = 0;
    int     _uplinkBandwidth           = 0;
    int     _flyDistance               = 0;
};
