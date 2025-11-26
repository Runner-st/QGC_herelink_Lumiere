#pragma once

#include "ServoControlSettings.h"

#include <QObject>
#include <QVariantList>

class ServoControlController : public QObject
{
    Q_OBJECT

public:
    explicit ServoControlController(QObject* parent = nullptr);

    Q_PROPERTY(ServoControlSettings* settings READ settings CONSTANT)
    Q_PROPERTY(QVariantList buttons READ buttons NOTIFY buttonsChanged)

    ServoControlSettings* settings() const { return _settings; }
    QVariantList buttons() const;

    Q_INVOKABLE void addButton(const QString& name, int output, int pwm);
    Q_INVOKABLE void updateButton(int index, const QString& name, int output, int pwm);
    Q_INVOKABLE void removeButton(int index);
    Q_INVOKABLE void triggerButton(int index);

signals:
    void buttonsChanged();

private:
    ServoControlSettings* _settings = nullptr;
};
