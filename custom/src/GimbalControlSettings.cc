#include "GimbalControlSettings.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>

namespace {
    const char* kSettingsGroup = "GimbalControl";
    const char* kPitchButtonsKey = "pitchButtons";
}

GimbalControlSettings::GimbalControlSettings(QObject* parent)
    : QObject(parent)
{
    _load();
}

QVariantList GimbalControlSettings::pitchButtons() const
{
    QVariantList list;
    for (const PitchButton& button : _pitchButtons) {
        QVariantMap buttonMap;
        buttonMap.insert(QStringLiteral("label"), button.label);
        buttonMap.insert(QStringLiteral("pitchOffset"), button.pitchOffset);
        list.append(buttonMap);
    }
    return list;
}

void GimbalControlSettings::addPitchButton(const QString& label, double pitchOffset)
{
    _pitchButtons.append({label, pitchOffset});
    _save();
    emit pitchButtonsChanged();
}

void GimbalControlSettings::updatePitchButton(int index, const QString& label, double pitchOffset)
{
    if (index < 0 || index >= _pitchButtons.count()) {
        return;
    }

    _pitchButtons[index] = {label, pitchOffset};
    _save();
    emit pitchButtonsChanged();
}

void GimbalControlSettings::removePitchButton(int index)
{
    if (index < 0 || index >= _pitchButtons.count()) {
        return;
    }

    _pitchButtons.removeAt(index);
    _save();
    emit pitchButtonsChanged();
}

void GimbalControlSettings::clearAll()
{
    _pitchButtons.clear();
    _save();
    emit pitchButtonsChanged();
}

void GimbalControlSettings::_load()
{
    QSettings settings;
    settings.beginGroup(kSettingsGroup);
    const QByteArray buttonBytes = settings.value(kPitchButtonsKey).toByteArray();

    if (!buttonBytes.isEmpty()) {
        const QJsonDocument document = QJsonDocument::fromJson(buttonBytes);
        if (document.isArray()) {
            const QJsonArray array = document.array();
            for (const QJsonValue& value : array) {
                if (!value.isObject()) {
                    continue;
                }
                const QJsonObject object = value.toObject();
                const QString label = object.value(QStringLiteral("label")).toString();
                const double pitchOffset = object.value(QStringLiteral("pitchOffset")).toDouble();
                _pitchButtons.append({label, pitchOffset});
            }
        }
    }

    settings.endGroup();
}

void GimbalControlSettings::_save() const
{
    QJsonArray array;
    for (const PitchButton& button : _pitchButtons) {
        QJsonObject object;
        object.insert(QStringLiteral("label"), button.label);
        object.insert(QStringLiteral("pitchOffset"), button.pitchOffset);
        array.append(object);
    }

    const QJsonDocument document(array);
    QSettings settings;
    settings.beginGroup(kSettingsGroup);
    settings.setValue(kPitchButtonsKey, document.toJson(QJsonDocument::Compact));
    settings.endGroup();
}
