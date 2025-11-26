#pragma once

#include <QObject>
#include <QVariantList>

class ServoControlSettings : public QObject
{
    Q_OBJECT

public:
    explicit ServoControlSettings(QObject* parent = nullptr);

    Q_PROPERTY(QVariantList buttons READ buttons NOTIFY buttonsChanged)

    QVariantList buttons() const;

    void addButton(const QString& name, int output, int pwm);
    void updateButton(int index, const QString& name, int output, int pwm);
    void removeButton(int index);

signals:
    void buttonsChanged();

private:
    struct ServoButton {
        QString name;
        int     output = 0;
        int     pwm    = 0;
    };

    QList<ServoButton> _buttons;

    void _load();
    void _save() const;
};
