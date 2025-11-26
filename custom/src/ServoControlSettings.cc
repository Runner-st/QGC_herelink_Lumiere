#include "ServoControlSettings.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>

namespace {
    const char* kSettingsGroup = "ServoControl";
    const char* kButtonsKey    = "buttons";
}

ServoControlSettings::ServoControlSettings(QObject* parent)
    : QObject(parent)
{
    _load();
}

QVariantList ServoControlSettings::buttons() const
{
    QVariantList list;
    for (const ServoButton& button : _buttons) {
        QVariantMap buttonMap;
        buttonMap.insert(QStringLiteral("name"), button.name);
        buttonMap.insert(QStringLiteral("output"), button.output);
        buttonMap.insert(QStringLiteral("pwm"), button.pwm);
        list.append(buttonMap);
    }
    return list;
}

void ServoControlSettings::addButton(const QString& name, int output, int pwm)
{
    _buttons.append({name, output, pwm});
    _save();
    emit buttonsChanged();
}

void ServoControlSettings::updateButton(int index, const QString& name, int output, int pwm)
{
    if (index < 0 || index >= _buttons.count()) {
        return;
    }

    _buttons[index] = {name, output, pwm};
    _save();
    emit buttonsChanged();
}

void ServoControlSettings::removeButton(int index)
{
    if (index < 0 || index >= _buttons.count()) {
        return;
    }

    _buttons.removeAt(index);
    _save();
    emit buttonsChanged();
}

void ServoControlSettings::_load()
{
    QSettings settings;
    settings.beginGroup(kSettingsGroup);
    const QByteArray buttonBytes = settings.value(kButtonsKey).toByteArray();

    if (!buttonBytes.isEmpty()) {
        const QJsonDocument document = QJsonDocument::fromJson(buttonBytes);
        if (document.isArray()) {
            const QJsonArray array = document.array();
            for (const QJsonValue& value : array) {
                if (!value.isObject()) {
                    continue;
                }
                const QJsonObject object = value.toObject();
                const QString name = object.value(QStringLiteral("name")).toString();
                const int output    = object.value(QStringLiteral("output")).toInt();
                const int pwm       = object.value(QStringLiteral("pwm")).toInt();
                _buttons.append({name, output, pwm});
            }
        }
    }

    settings.endGroup();
}

void ServoControlSettings::_save() const
{
    QJsonArray array;
    for (const ServoButton& button : _buttons) {
        QJsonObject object;
        object.insert(QStringLiteral("name"), button.name);
        object.insert(QStringLiteral("output"), button.output);
        object.insert(QStringLiteral("pwm"), button.pwm);
        array.append(object);
    }

    const QJsonDocument document(array);
    QSettings settings;
    settings.beginGroup(kSettingsGroup);
    settings.setValue(kButtonsKey, document.toJson(QJsonDocument::Compact));
    settings.endGroup();
}
