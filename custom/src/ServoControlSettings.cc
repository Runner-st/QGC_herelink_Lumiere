#include "ServoControlSettings.h"

#include "SettingsFact.h"

#include <QtCore/QJsonArray>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QJsonParseError>
#include <QtCore/QString>
#include <QtQml/qqml.h>

DECLARE_SETTINGGROUP(ServoControl, "ServoControl")
{
    static bool registered = false;
    if (!registered) {
        qmlRegisterUncreatableType<ServoControlSettings>("Herelink.ServoControl", 1, 0, "ServoControlSettings", QStringLiteral("Reference only"));
        registered = true;
    }

    _buttonsJsonFact = _createSettingsFact(buttonsJsonName);
    connect(_buttonsJsonFact, &Fact::rawValueChanged, this, &ServoControlSettings::_updateButtons);
    _updateButtons();
}

DECLARE_SETTINGSFACT(ServoControlSettings, buttonsJson)

void ServoControlSettings::setButtons(const QVariantList& buttons)
{
    if (!_buttonsJsonFact) {
        return;
    }

    const QVariantList sanitized = _sanitizeButtons(buttons);
    QJsonArray array;
    for (const QVariant& value : sanitized) {
        const QVariantMap map = value.toMap();
        QJsonObject object;
        object.insert(QStringLiteral("name"), map.value(QStringLiteral("name")).toString());
        object.insert(QStringLiteral("servoOutput"), map.value(QStringLiteral("servoOutput")).toInt());
        object.insert(QStringLiteral("pulseWidth"), map.value(QStringLiteral("pulseWidth")).toDouble());
        array.append(object);
    }

    const QJsonDocument document(array);
    const QString json = QString::fromUtf8(document.toJson(QJsonDocument::Compact));
    if (_buttonsJsonFact->rawValue().toString() != json) {
        _buttonsJsonFact->setRawValue(json);
    }
}

void ServoControlSettings::_updateButtons()
{
    QVariantList newButtons;
    if (_buttonsJsonFact) {
        const QString json = _buttonsJsonFact->rawValue().toString();
        if (!json.isEmpty()) {
            QJsonParseError error{};
            const QJsonDocument document = QJsonDocument::fromJson(json.toUtf8(), &error);
            if (error.error == QJsonParseError::NoError && document.isArray()) {
                const QJsonArray array = document.array();
                newButtons.reserve(array.size());
                for (const QJsonValue& value : array) {
                    if (!value.isObject()) {
                        continue;
                    }
                    const QJsonObject object = value.toObject();
                    QVariantMap map;
                    map.insert(QStringLiteral("name"), object.value(QStringLiteral("name")).toString());
                    map.insert(QStringLiteral("servoOutput"), object.value(QStringLiteral("servoOutput")).toInt());
                    map.insert(QStringLiteral("pulseWidth"), object.value(QStringLiteral("pulseWidth")).toDouble());
                    newButtons.append(map);
                }
            }
        }
    }

    const QVariantList sanitized = _sanitizeButtons(newButtons);
    if (_buttons != sanitized) {
        _buttons = sanitized;
        emit buttonsChanged();
    }
}

QVariantList ServoControlSettings::_sanitizeButtons(const QVariantList& buttons) const
{
    QVariantList sanitized;
    sanitized.reserve(buttons.size());
    for (const QVariant& value : buttons) {
        const QVariantMap map = value.toMap();
        const QString name = map.value(QStringLiteral("name")).toString();
        const int servoOutput = map.value(QStringLiteral("servoOutput")).toInt();
        const double pulseWidth = map.value(QStringLiteral("pulseWidth")).toDouble();

        if (name.trimmed().isEmpty()) {
            continue;
        }
        QVariantMap cleaned;
        cleaned.insert(QStringLiteral("name"), name);
        cleaned.insert(QStringLiteral("servoOutput"), servoOutput);
        cleaned.insert(QStringLiteral("pulseWidth"), pulseWidth);
        sanitized.append(cleaned);
    }
    return sanitized;
}
