#pragma once

#include "GimbalControlSettings.h"

#include <QObject>
#include <QVariantList>

class GimbalControlController : public QObject
{
    Q_OBJECT

public:
    explicit GimbalControlController(QObject* parent = nullptr);

    Q_PROPERTY(GimbalControlSettings* settings READ settings CONSTANT)
    Q_PROPERTY(QVariantList pitchButtons READ pitchButtons NOTIFY pitchButtonsChanged)

    GimbalControlSettings* settings() const { return _settings; }
    QVariantList pitchButtons() const;

    // Settings management (called from settings page)
    Q_INVOKABLE void addPitchButton(const QString& label, double pitchOffset);
    Q_INVOKABLE void updatePitchButton(int index, const QString& label, double pitchOffset);
    Q_INVOKABLE void removePitchButton(int index);

    // Runtime actions (called from fly view)
    Q_INVOKABLE void triggerPitchButton(int index);
    Q_INVOKABLE void resetGimbalToLevel();

signals:
    void pitchButtonsChanged();

private:
    GimbalControlSettings* _settings = nullptr;

    void _sendGimbalPitchCommand(double pitchDegrees);
};
