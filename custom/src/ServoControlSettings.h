#pragma once

#include "SettingsGroup.h"

#include <QtCore/QVariantList>

class ServoControlSettings : public SettingsGroup
{
    Q_OBJECT

public:
    explicit ServoControlSettings(QObject* parent = nullptr);

    DEFINE_SETTING_NAME_GROUP()
    DEFINE_SETTINGFACT(buttonsJson)

    Q_PROPERTY(QVariantList buttons READ buttons NOTIFY buttonsChanged)

    QVariantList buttons() const { return _buttons; }
    void setButtons(const QVariantList& buttons);

signals:
    void buttonsChanged();

private slots:
    void _updateButtons();

private:
    QVariantList _sanitizeButtons(const QVariantList& buttons) const;

    QVariantList _buttons;
};
