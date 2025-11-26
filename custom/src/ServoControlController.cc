#include "ServoControlController.h"

#include "QGCApplication.h"
#include "QGCToolbox.h"
#include "MultiVehicleManager.h"
#include "Vehicle.h"

ServoControlController::ServoControlController(QObject* parent)
    : QObject(parent)
    , _settings(new ServoControlSettings(this))
{
    connect(_settings, &ServoControlSettings::buttonsChanged, this, &ServoControlController::buttonsChanged);
}

QVariantList ServoControlController::buttons() const
{
    return _settings->buttons();
}

void ServoControlController::addButton(const QString& name, int output, int pwm)
{
    _settings->addButton(name, output, pwm);
}

void ServoControlController::updateButton(int index, const QString& name, int output, int pwm)
{
    _settings->updateButton(index, name, output, pwm);
}

void ServoControlController::removeButton(int index)
{
    _settings->removeButton(index);
}

void ServoControlController::triggerButton(int index)
{
    const QVariantList currentButtons = buttons();
    if (index < 0 || index >= currentButtons.count()) {
        return;
    }

    Vehicle* activeVehicle = qgcApp()->toolbox()->multiVehicleManager()->activeVehicle();
    if (!activeVehicle) {
        return;
    }

    const QVariantMap button = currentButtons[index].toMap();
    const int servoOutput = button.value(QStringLiteral("output")).toInt();
    const int pwmWidth    = button.value(QStringLiteral("pwm")).toInt();

    activeVehicle->sendCommand(activeVehicle->defaultComponentId(), MAV_CMD_DO_SET_SERVO, true /* showError */, servoOutput, pwmWidth);
}
