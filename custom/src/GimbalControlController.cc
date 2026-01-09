#include "GimbalControlController.h"

#include "QGCApplication.h"
#include "QGCToolbox.h"
#include "MultiVehicleManager.h"
#include "Vehicle.h"
#include "GimbalController.h"

#include <QDebug>

GimbalControlController::GimbalControlController(QObject* parent)
    : QObject(parent)
    , _settings(new GimbalControlSettings(this))
{
    connect(_settings, &GimbalControlSettings::pitchButtonsChanged, this, &GimbalControlController::pitchButtonsChanged);
}

QVariantList GimbalControlController::pitchButtons() const
{
    return _settings->pitchButtons();
}

void GimbalControlController::addPitchButton(const QString& label, double pitchOffset)
{
    _settings->addPitchButton(label, pitchOffset);
}

void GimbalControlController::updatePitchButton(int index, const QString& label, double pitchOffset)
{
    _settings->updatePitchButton(index, label, pitchOffset);
}

void GimbalControlController::removePitchButton(int index)
{
    _settings->removePitchButton(index);
}

void GimbalControlController::triggerPitchButton(int index)
{
    const QVariantList currentButtons = pitchButtons();
    if (index < 0 || index >= currentButtons.count()) {
        qWarning() << "GimbalControlController::triggerPitchButton: invalid index" << index;
        return;
    }

    const QVariantMap button = currentButtons[index].toMap();
    const double pitchOffset = button.value(QStringLiteral("pitchOffset")).toDouble();

    _sendGimbalPitchCommand(pitchOffset);
}

void GimbalControlController::resetGimbalToLevel()
{
    _sendGimbalPitchCommand(0.0);
}

void GimbalControlController::_sendGimbalPitchCommand(double pitchDegrees)
{
    Vehicle* vehicle = qgcApp()->toolbox()->multiVehicleManager()->activeVehicle();
    if (!vehicle) {
        qWarning() << "GimbalControlController: No active vehicle";
        return;
    }

    GimbalController* gimbalCtrl = vehicle->gimbalController();
    if (!gimbalCtrl) {
        qWarning() << "GimbalControlController: No gimbal controller available";
        return;
    }

    // Use sendPitchBodyYaw with auto-leveling flags
    // Pitch: negative = down, positive = up
    // Yaw: 0 = forward (vehicle frame)
    // The gimbalController handles the MAVLink command with proper flags for auto-leveling
    gimbalCtrl->sendPitchBodyYaw(static_cast<float>(pitchDegrees), 0.0f, true);
}
