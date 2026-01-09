#pragma once

#include <QObject>
#include <QVariantList>

class GimbalControlSettings : public QObject
{
    Q_OBJECT

public:
    explicit GimbalControlSettings(QObject* parent = nullptr);

    Q_PROPERTY(QVariantList pitchButtons READ pitchButtons NOTIFY pitchButtonsChanged)

    QVariantList pitchButtons() const;

    void addPitchButton(const QString& label, double pitchOffset);
    void updatePitchButton(int index, const QString& label, double pitchOffset);
    void removePitchButton(int index);
    void clearAll();

signals:
    void pitchButtonsChanged();

private:
    struct PitchButton {
        QString label;
        double  pitchOffset;
    };

    QList<PitchButton> _pitchButtons;

    void _load();
    void _save() const;
};
