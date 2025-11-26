#pragma once

#include "HerelinkOptions.h"
#include "ServoControlController.h"

#include "QGCCorePlugin.h"
#include "QGCLoggingCategory.h"

#include <QObject>

Q_DECLARE_LOGGING_CATEGORY(HerelinkCorePluginLog)

class QmlComponentInfo;
class Vehicle;

class HerelinkCorePlugin : public QGCCorePlugin
{
    Q_OBJECT

public:
    HerelinkCorePlugin(QGCApplication* app, QGCToolbox* toolbox);

    Q_PROPERTY(bool isHerelink READ isHerelink CONSTANT)
    Q_PROPERTY(ServoControlController* servoControlController READ servoControlController CONSTANT)
    bool isHerelink (void) const { return true; }
    ServoControlController* servoControlController() const { return _servoControlController; }

    // Overrides from QGCCorePlugin
    QGCOptions* options                                (void) override { return qobject_cast<QGCOptions*>(_herelinkOptions); }
    QVariantList& settingsPages                        (void) override;
    bool        overrideSettingsGroupVisibility        (QString name) override;
    bool        adjustSettingMetaData                  (const QString& settingsGroup, FactMetaData& metaData) override;
    void        factValueGridCreateDefaultSettings     (const QString& defaultSettingsGroup) override;

    // Overrides from QGCTool
    void setToolbox(QGCToolbox* toolbox) override;

private slots:
    void _activeVehicleChanged(Vehicle* activeVehicle);

private:
    QVariantList              _settingsList;
    QmlComponentInfo*         _settingsGeneral        = nullptr;
    QmlComponentInfo*         _settingsCommLinks      = nullptr;
    QmlComponentInfo*         _settingsOfflineMaps    = nullptr;
    QmlComponentInfo*         _settingsTaisync        = nullptr;
    QmlComponentInfo*         _settingsMicrohard      = nullptr;
    QmlComponentInfo*         _settingsMavlink        = nullptr;
    QmlComponentInfo*         _settingsRemoteId       = nullptr;
    QmlComponentInfo*         _settingsConsole        = nullptr;
    QmlComponentInfo*         _settingsHelp           = nullptr;
#if defined(QT_DEBUG)
    QmlComponentInfo*         _settingsMockLink       = nullptr;
    QmlComponentInfo*         _settingsDebug          = nullptr;
    QmlComponentInfo*         _settingsPalette        = nullptr;
#endif
    QmlComponentInfo*         _settingsServoControl   = nullptr;

    HerelinkOptions*          _herelinkOptions        = nullptr;
    ServoControlController*   _servoControlController = nullptr;
};
