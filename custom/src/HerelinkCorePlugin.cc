#include "HerelinkCorePlugin.h"

#include "AutoConnectSettings.h"
#include "VideoSettings.h"
#include "AppSettings.h"
#include "QGCApplication.h"
#include "QGCToolbox.h"
#include "MultiVehicleManager.h"
#include "JoystickManager.h"
#include "HorizontalFactValueGrid.h"
#include "InstrumentValueData.h"
#include "QmlComponentInfo.h"

#include <list>
#include <QQmlEngine>

QGC_LOGGING_CATEGORY(HerelinkCorePluginLog, "HerelinkCorePluginLog")

HerelinkCorePlugin::HerelinkCorePlugin(QGCApplication *app, QGCToolbox* toolbox)
    : QGCCorePlugin(app, toolbox)
{

}

void HerelinkCorePlugin::setToolbox(QGCToolbox* toolbox)
{
    QGCCorePlugin::setToolbox(toolbox);

    qmlRegisterUncreatableType<ServoControlController>("QGroundControl.ServoControl", 1, 0, "ServoControlController", "Reference only");
    qmlRegisterUncreatableType<ServoControlSettings>("QGroundControl.ServoControl", 1, 0, "ServoControlSettings", "Reference only");

    _herelinkOptions = new HerelinkOptions(this, nullptr);
    _servoControlController = new ServoControlController(this);

    auto multiVehicleManager = qgcApp()->toolbox()->multiVehicleManager();
    connect(multiVehicleManager, &MultiVehicleManager::activeVehicleChanged, this, &HerelinkCorePlugin::_activeVehicleChanged);
}

QVariantList& HerelinkCorePlugin::settingsPages()
{
    if (!_settingsList.isEmpty()) {
        return _settingsList;
    }

    _settingsGeneral = new QmlComponentInfo(tr("General"), QUrl::fromUserInput("qrc:/qml/GeneralSettings.qml"), QUrl::fromUserInput("qrc:/res/gear-white.svg"), this);
    _settingsList.append(QVariant::fromValue(_settingsGeneral));

    _settingsCommLinks = new QmlComponentInfo(tr("Comm Links"), QUrl::fromUserInput("qrc:/qml/LinkSettings.qml"), QUrl::fromUserInput("qrc:/res/waves.svg"), this);
    _settingsList.append(QVariant::fromValue(_settingsCommLinks));

    _settingsServoControl = new QmlComponentInfo(tr("Servo Control"), QUrl::fromUserInput("qrc:/qml/ServoControlSettings.qml"), QUrl::fromUserInput("qrc:/res/action.svg"), this);
    _settingsList.append(QVariant::fromValue(_settingsServoControl));

    _settingsOfflineMaps = new QmlComponentInfo(tr("Offline Maps"), QUrl::fromUserInput("qrc:/qml/OfflineMap.qml"), QUrl::fromUserInput("qrc:/res/waves.svg"), this);
    _settingsList.append(QVariant::fromValue(_settingsOfflineMaps));

#if defined(QGC_GST_TAISYNC_ENABLED)
    _settingsTaisync = new QmlComponentInfo(tr("Taisync"), QUrl::fromUserInput("qrc:/qml/TaisyncSettings.qml"), QUrl(), this);
    _settingsList.append(QVariant::fromValue(_settingsTaisync));
#endif

#if defined(QGC_GST_MICROHARD_ENABLED)
    _settingsMicrohard = new QmlComponentInfo(tr("Microhard"), QUrl::fromUserInput("qrc:/qml/MicrohardSettings.qml"), QUrl(), this);
    _settingsList.append(QVariant::fromValue(_settingsMicrohard));
#endif

    _settingsMavlink = new QmlComponentInfo(tr("MAVLink"), QUrl::fromUserInput("qrc:/qml/MavlinkSettings.qml"), QUrl::fromUserInput("qrc:/res/waves.svg"), this);
    _settingsList.append(QVariant::fromValue(_settingsMavlink));

    _settingsRemoteId = new QmlComponentInfo(tr("Remote ID"), QUrl::fromUserInput("qrc:/qml/RemoteIDSettings.qml"), QUrl(), this);
    _settingsList.append(QVariant::fromValue(_settingsRemoteId));

    _settingsConsole = new QmlComponentInfo(tr("Console"), QUrl::fromUserInput("qrc:/qml/QGroundControl/Controls/AppMessages.qml"), QUrl(), this);
    _settingsList.append(QVariant::fromValue(_settingsConsole));

    _settingsHelp = new QmlComponentInfo(tr("Help"), QUrl::fromUserInput("qrc:/qml/HelpSettings.qml"), QUrl(), this);
    _settingsList.append(QVariant::fromValue(_settingsHelp));

#if defined(QT_DEBUG)
    _settingsMockLink = new QmlComponentInfo(tr("Mock Link"), QUrl::fromUserInput("qrc:/qml/MockLink.qml"), QUrl(), this);
    _settingsList.append(QVariant::fromValue(_settingsMockLink));

    _settingsDebug = new QmlComponentInfo(tr("Debug"), QUrl::fromUserInput("qrc:/qml/DebugWindow.qml"), QUrl(), this);
    _settingsList.append(QVariant::fromValue(_settingsDebug));

    _settingsPalette = new QmlComponentInfo(tr("Palette Test"), QUrl::fromUserInput("qrc:/qml/QmlTest.qml"), QUrl(), this);
    _settingsList.append(QVariant::fromValue(_settingsPalette));
#endif

    return _settingsList;
}

bool HerelinkCorePlugin::overrideSettingsGroupVisibility(QString name)
{
    // Hide all AutoConnect settings
    return name != AutoConnectSettings::name;
}

bool HerelinkCorePlugin::adjustSettingMetaData(const QString& settingsGroup, FactMetaData& metaData)
{
    if (settingsGroup == AppSettings::settingsGroup) {
        //-- Default herelink fontsize of 10, it is a nice starting point
        if (metaData.name() == AppSettings::appFontPointSizeName) {
            uint32_t fontSize = 10;
            metaData.setRawDefaultValue(fontSize);
            // Show setting in ui
            return true;
        }
        //-- Default Palette Dark
        if (metaData.name() == AppSettings::indoorPaletteName) {
            QVariant outdoorPalette;
            outdoorPalette = 1;
            metaData.setRawDefaultValue(outdoorPalette);
            // Show setting in ui
            return true;
        }
    }
    if (settingsGroup == AutoConnectSettings::settingsGroup) {
        // We have to adjust the Herelink UDP autoconnect settings for the AirLink
        if (metaData.name() == AutoConnectSettings::udpListenPortName) {
            metaData.setRawDefaultValue(14551);
        } else if (metaData.name() == AutoConnectSettings::udpTargetHostIPName) {
            metaData.setRawDefaultValue(QStringLiteral("127.0.0.1"));
        } else if (metaData.name() == AutoConnectSettings::udpTargetHostPortName) {
            metaData.setRawDefaultValue(15552);
        } else {
            // Disable all the other autoconnect types
            const std::list<const char *> disabledAndHiddenSettings = {
                AutoConnectSettings::autoConnectPixhawkName,
                AutoConnectSettings::autoConnectSiKRadioName,
                AutoConnectSettings::autoConnectPX4FlowName,
                AutoConnectSettings::autoConnectRTKGPSName,
                AutoConnectSettings::autoConnectLibrePilotName,
                AutoConnectSettings::autoConnectNmeaPortName,
                AutoConnectSettings::autoConnectZeroConfName,
            };
            for (const char * disabledAndHiddenSetting : disabledAndHiddenSettings) {
                if (disabledAndHiddenSetting == metaData.name()) {
                    metaData.setRawDefaultValue(false);
                }
            }
        }
    } else if (settingsGroup == VideoSettings::settingsGroup) {
        if (metaData.name() == VideoSettings::rtspTimeoutName) {
            metaData.setRawDefaultValue(60);
        } else if (metaData.name() == VideoSettings::videoSourceName) {
            metaData.setRawDefaultValue(VideoSettings::videoSourceHerelinkAirUnit);
        }
    } else if (settingsGroup == AppSettings::settingsGroup) {
        if (metaData.name() == AppSettings::androidSaveToSDCardName) {
            metaData.setRawDefaultValue(true);
        }
    }

    return true; // Show all settings in ui
}

void HerelinkCorePlugin::_activeVehicleChanged(Vehicle* activeVehicle)
{
    if (activeVehicle) {
        QString herelinkButtonsJoystickName("gpio-keys");

        auto joystickManager = qgcApp()->toolbox()->joystickManager();
        if (joystickManager->activeJoystickName() != herelinkButtonsJoystickName) {
            if (!joystickManager->setActiveJoystickName(herelinkButtonsJoystickName)) {
                qgcApp()->showAppMessage("Warning: Herelink buttton setup failed. Buttons will not work.");
                return;
            }           
        }
        activeVehicle->setJoystickEnabled(true);
    }
}

// Same as original, only we set font size to medium by default for Herelink
void HerelinkCorePlugin::factValueGridCreateDefaultSettings(const QString& defaultSettingsGroup)
{
    HorizontalFactValueGrid factValueGrid(defaultSettingsGroup);

    bool        includeFWValues = factValueGrid.vehicleClass() == QGCMAVLink::VehicleClassFixedWing || factValueGrid.vehicleClass() == QGCMAVLink::VehicleClassVTOL || factValueGrid.vehicleClass() == QGCMAVLink::VehicleClassAirship;

    factValueGrid.setFontSize(FactValueGrid::MediumFontSize);

    factValueGrid.appendColumn();
    factValueGrid.appendColumn();
    factValueGrid.appendColumn();
    if (includeFWValues) {
        factValueGrid.appendColumn();
    }
    factValueGrid.appendRow();

    int                 rowIndex    = 0;
    QmlObjectListModel* column      = factValueGrid.columns()->value<QmlObjectListModel*>(0);

    InstrumentValueData* value = column->value<InstrumentValueData*>(rowIndex++);
    value->setFact("Vehicle", "AltitudeRelative");
    value->setIcon("arrow-thick-up.svg");
    value->setText(value->fact()->shortDescription());
    value->setShowUnits(true);

    value = column->value<InstrumentValueData*>(rowIndex++);
    value->setFact("Vehicle", "DistanceToHome");
    value->setIcon("bookmark copy 3.svg");
    value->setText(value->fact()->shortDescription());
    value->setShowUnits(true);

    rowIndex    = 0;
    column      = factValueGrid.columns()->value<QmlObjectListModel*>(1);

    value = column->value<InstrumentValueData*>(rowIndex++);
    value->setFact("Vehicle", "ClimbRate");
    value->setIcon("arrow-simple-up.svg");
    value->setText(value->fact()->shortDescription());
    value->setShowUnits(true);

    value = column->value<InstrumentValueData*>(rowIndex++);
    value->setFact("Vehicle", "GroundSpeed");
    value->setIcon("arrow-simple-right.svg");
    value->setText(value->fact()->shortDescription());
    value->setShowUnits(true);


    if (includeFWValues) {
        rowIndex    = 0;
        column      = factValueGrid.columns()->value<QmlObjectListModel*>(2);

        value = column->value<InstrumentValueData*>(rowIndex++);
        value->setFact("Vehicle", "AirSpeed");
        value->setText("AirSpd");
        value->setShowUnits(true);

        value = column->value<InstrumentValueData*>(rowIndex++);
        value->setFact("Vehicle", "ThrottlePct");
        value->setText("Thr");
        value->setShowUnits(true);
    }

    rowIndex    = 0;
    column      = factValueGrid.columns()->value<QmlObjectListModel*>(includeFWValues ? 3 : 2);

    value = column->value<InstrumentValueData*>(rowIndex++);
    value->setFact("Vehicle", "FlightTime");
    value->setIcon("timer.svg");
    value->setText(value->fact()->shortDescription());
    value->setShowUnits(false);

    value = column->value<InstrumentValueData*>(rowIndex++);
    value->setFact("Vehicle", "FlightDistance");
    value->setIcon("travel-walk.svg");
    value->setText(value->fact()->shortDescription());
    value->setShowUnits(true);
}
