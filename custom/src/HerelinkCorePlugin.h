#pragma once

#include "HerelinkOptions.h"

#include "QGCApplication.h"
#include "QGCCorePlugin.h"
#include "QGCLoggingCategory.h"

#include <QObject>
#include <QtCore/qapplicationstatic.h>

#include "ServoControlController.h"

Q_DECLARE_LOGGING_CATEGORY(HerelinkCorePluginLog)

class HerelinkCorePlugin : public QGCCorePlugin
{
    Q_OBJECT

public:
    HerelinkCorePlugin(QObject* parent = nullptr);

    static HerelinkCorePlugin* instance();

    Q_PROPERTY(bool isHerelink READ isHerelink CONSTANT)
    Q_PROPERTY(QObject* servoControlController READ servoControlController CONSTANT)
    bool isHerelink (void) const { return true; }

    // Overrides from QGCCorePlugin
    QGCOptions* options                                (void) override { return qobject_cast<QGCOptions*>(_herelinkOptions); }
    bool        overrideSettingsGroupVisibility        (const QString& name) override;
    bool        adjustSettingMetaData                  (const QString& settingsGroup, FactMetaData& metaData) override;
    void        factValueGridCreateDefaultSettings     (FactValueGrid* factValueGrid) override;


    QObject* servoControlController() const { return _servoControlController; }

private slots:
    void _activeVehicleChanged(Vehicle* activeVehicle);

private:
    HerelinkOptions* _herelinkOptions = nullptr;
    ServoControlController* _servoControlController = nullptr;
};

Q_APPLICATION_STATIC(HerelinkCorePlugin, _herelinkCorePluginInstance);
