#include "ServoControlController.h"

#include "QGCApplication.h"
#include "MultiVehicleManager.h"
#include "ServoControlSettings.h"
#include "Vehicle.h"

#include <QtCore/QVariantMap>

#include "QGCMAVLink.h"

ServoControlController::ServoControlController(QObject* parent)
    : QObject(parent)
    , _settings(new ServoControlSettings(this))
{
    connect(_settings, &ServoControlSettings::buttonsChanged, this, &ServoControlController::_onButtonsChanged);
    _onButtonsChanged();
}

QVariantList ServoControlController::buttons() const
{
    return _settings ? _settings->buttons() : QVariantList{};
}

void ServoControlController::addButton(const QString& name, int servoOutput, int pulseWidth)
{
    if (!_settings) {
        return;
    }

    QVariantList current = _settings->buttons();
    QVariantMap map;
    map.insert(QStringLiteral("name"), name);
    map.insert(QStringLiteral("servoOutput"), servoOutput);
    map.insert(QStringLiteral("pulseWidth"), pulseWidth);
    current.append(map);
    _settings->setButtons(current);
}

void ServoControlController::updateButton(int index, const QString& name, int servoOutput, int pulseWidth)
{
    if (!_settings) {
        return;
    }

    QVariantList current = _settings->buttons();
    if (index < 0 || index >= current.size()) {
        return;
    }

    QVariantMap map = current.at(index).toMap();
    map.insert(QStringLiteral("name"), name);
    map.insert(QStringLiteral("servoOutput"), servoOutput);
    map.insert(QStringLiteral("pulseWidth"), pulseWidth);
    current[index] = map;
    _settings->setButtons(current);
}

void ServoControlController::removeButton(int index)
{
    if (!_settings) {
        return;
    }

    QVariantList current = _settings->buttons();
    if (index < 0 || index >= current.size()) {
        return;
    }

    current.removeAt(index);
    _settings->setButtons(current);

    if (_activeButtonIndex == index) {
        _activeButtonIndex = -1;
        emit activeButtonIndexChanged(_activeButtonIndex);
    } else if (_activeButtonIndex > index) {
        _activeButtonIndex--;
        emit activeButtonIndexChanged(_activeButtonIndex);
    }
}

void ServoControlController::triggerButton(int index)
{
    if (!_settings) {
        return;
    }

    const QVariantList current = _settings->buttons();
    if (index < 0 || index >= current.size()) {
        return;
    }

    Vehicle* vehicle = MultiVehicleManager::instance()->activeVehicle();
    if (!vehicle) {
        qgcApp()->showAppMessage(tr("No active vehicle to send servo command."));
        return;
    }

    const QVariantMap map = current.at(index).toMap();
    const float servoOutput = static_cast<float>(map.value(QStringLiteral("servoOutput")).toInt());
    const float pulseWidth = static_cast<float>(map.value(QStringLiteral("pulseWidth")).toDouble());

    vehicle->sendMavCommand(vehicle->defaultComponentId(), MAV_CMD_DO_SET_SERVO, true, servoOutput, pulseWidth);

    if (_activeButtonIndex != index) {
        _activeButtonIndex = index;
        emit activeButtonIndexChanged(_activeButtonIndex);
    }
}

void ServoControlController::_onButtonsChanged()
{
    emit buttonsChanged();
    const int buttonCount = _settings ? _settings->buttons().count() : 0;
    if (_activeButtonIndex >= buttonCount) {
        _activeButtonIndex = -1;
        emit activeButtonIndexChanged(_activeButtonIndex);
    }
}
