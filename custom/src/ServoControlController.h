#pragma once

#include <QtCore/QObject>
#include <QtCore/QVariantList>

class ServoControlSettings;

class ServoControlController : public QObject
{
    Q_OBJECT

public:
    explicit ServoControlController(QObject* parent = nullptr);

    Q_PROPERTY(QVariantList buttons READ buttons NOTIFY buttonsChanged)
    Q_PROPERTY(int activeButtonIndex READ activeButtonIndex NOTIFY activeButtonIndexChanged)

    QVariantList buttons() const;
    int activeButtonIndex() const { return _activeButtonIndex; }

    Q_INVOKABLE void addButton(const QString& name, int servoOutput, int pulseWidth);
    Q_INVOKABLE void updateButton(int index, const QString& name, int servoOutput, int pulseWidth);
    Q_INVOKABLE void removeButton(int index);
    Q_INVOKABLE void triggerButton(int index);

signals:
    void buttonsChanged();
    void activeButtonIndexChanged(int index);

private slots:
    void _onButtonsChanged();

private:
    ServoControlSettings* _settings = nullptr;
    int _activeButtonIndex = -1;
};
