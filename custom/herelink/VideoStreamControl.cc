#include <QDebug>

#include "LinkInterface.h"
#include "QGCApplication.h"
#include "VideoStreamControl.h"

QGC_LOGGING_CATEGORY(VideoStreamControlLog, "VideoStreamControlLog")

VideoStreamControl::VideoStreamControl()
    : QObject()
    , _systemId(-1)
    , _linkInterface(NULL)
    , _cameraServiceUid(0)
    , _cameraCount(0)
    , _settingInProgress(false)
{
    _mavlinkProtocol = qgcApp()->toolbox()->mavlinkProtocol();
    connect(_mavlinkProtocol, &MAVLinkProtocol::messageReceived, this, &VideoStreamControl::_mavlinkMessageReceived);

    _videoSettings = qgcApp()->toolbox()->settingsManager()->videoSettings();
    _cameraIdSetting = _videoSettings->cameraId()->rawValue().toUInt();

    connect(_videoSettings->cameraId(), &Fact::rawValueChanged, this, &VideoStreamControl::_cameraIdChanged);
    connect(&_settingInProgressTimer, &QTimer::timeout, this, &VideoStreamControl::_settingInProgressTimeout);
    connect(&_settingInProgressTimerAck, &QTimer::timeout, this, &VideoStreamControl::_settingInProgressAckTimeout);
}

VideoStreamControl::~VideoStreamControl()
{

}

void VideoStreamControl::_mavlinkMessageReceived(LinkInterface* link, mavlink_message_t message)
{
    if (message.msgid == MAVLINK_MSG_ID_COMMAND_ACK) {
        mavlink_command_ack_t ack;
        mavlink_msg_command_ack_decode(&message, &ack);

        if (ack.command == MAV_CMD_VIDEO_START_STREAMING) {
            qDebug() << "[MAVLINK] VIDEO_START_STREAMING ACK result =" << ack.result;
            if (ack.result == MAV_RESULT_ACCEPTED) {
                qDebug() << "[SWITCH] video start accepted, unlock UI";
                _settingInProgressTimerAck.setInterval(4000);
                _settingInProgressTimerAck.setSingleShot(true);
                _settingInProgressTimerAck.start();
            }
        }
        // else
        // {
        //     qDebug() << "[MAVLINK] COMMAND_ACK"
        //              << "command =" << ack.command
        //              << "result =" << ack.result;
        // }

    }
    if (message.msgid == MAVLINK_MSG_ID_VIDEO_STREAM_STATUS) {
        mavlink_video_stream_status_t status;
        mavlink_msg_video_stream_status_decode(&message, &status);

        qDebug() << "[MAVLINK] VIDEO_STREAM_STATUS"
                 << "stream_id =" << status.stream_id
                 << "framerate =" << status.framerate
                 << "bitrate =" << status.bitrate;
    }
    if (message.msgid == MAVLINK_MSG_ID_CAMERA_SETTINGS) {
        mavlink_camera_settings_t settings;
        mavlink_msg_camera_settings_decode(&message, &settings);

        qDebug() << "[MAVLINK] CAMERA_SETTINGS"
                 << "mode =" << settings.mode_id;
    }
    if (message.msgid == MAVLINK_MSG_ID_HEARTBEAT && message.compid == MAV_COMP_ID_CAMERA) {
        _handleHeartbeatInfo(link, message);
    }
}

void VideoStreamControl::_settingInProgressTimeout()
{
    qCDebug(VideoStreamControlLog) << "Time out to setting camera, unlock UI!";
    _setSettingInProgress(false);
}

void VideoStreamControl::_settingInProgressAckTimeout()
{
    qDebug() << "Timeout after ACK from herelink (for changing camera), unlock UI!";
    _setSettingInProgress(false);
}


void VideoStreamControl::_cameraIdChanged()
{
    qDebug() << "[SWITCH] cameraIdChanged rawValue ="
             << _videoSettings->cameraId()->rawValue().toUInt();
    _setCameraIdLockUi(true);
}

void VideoStreamControl::_handleHeartbeatInfo(LinkInterface* link, mavlink_message_t& message)
{
    mavlink_heartbeat_t heartbeat;
    mavlink_msg_heartbeat_decode(&message, &heartbeat);

    if (message.sysid == _systemId) {
        if (heartbeat.custom_mode == _cameraServiceUid) {
            // qDebug() << "[Heartbeat] skip " << _cameraServiceUid;
            return;
        } else {
            // customMode is a uid, the change means remote peer reset
            // need to restart video streaming
            qCDebug(VideoStreamControlLog) << "remote peer reset";
            _systemId = 0;
        }
    }

    qCDebug(VideoStreamControlLog) << "First camera heartbeat:" << message.sysid << heartbeat.system_status << heartbeat.custom_mode;

    _systemId = message.sysid;
    _cameraServiceUid = heartbeat.custom_mode;
     // customMode 32bits: bits 25-31: camera count, bits 16-24: timestamp, bits 0-15 remote peer pid
    _cameraCount = _cameraServiceUid >> 24;
    qCDebug(VideoStreamControlLog) << "Camera found uid:" << _cameraServiceUid << "count:" << _cameraCount;
    qDebug() << "[Heartbeat] Camera found uid:" << _cameraServiceUid << "count:" << _cameraCount;

    _linkInterface = link;

    _startVideoStreaming();
}

void VideoStreamControl::_setCameraId()
{
    if(_cameraCount > 1) {
        _cameraIdSetting = _videoSettings->cameraId()->rawValue().toUInt();
        _startVideoStreaming();
    }
}

void VideoStreamControl::_setCameraIdLockUi(bool lockUi)
{
    if (_linkInterface == NULL) {
        return;
    }
    _cameraIdSetting = _videoSettings->cameraId()->rawValue().toUInt();

    _setCameraId();

    if (lockUi) {
        _setSettingInProgress(true);
    }
}

void VideoStreamControl::_startVideoStreaming() {
    if (_linkInterface == NULL) {
        return;
    }
    qCDebug(VideoStreamControlLog) << "Start Video Stream" << _systemId;
    qDebug() << "[SWITCH] _startVideoStreaming start"
             << "cameraId =" << _cameraIdSetting
             << "systemId =" << _systemId;
    mavlink_message_t msg;
    mavlink_msg_command_long_pack(_mavlinkProtocol->getSystemId(), _mavlinkProtocol->getComponentId(), &msg,
                                      _systemId, MAV_COMP_ID_CAMERA,
                                      MAV_CMD_VIDEO_START_STREAMING, 0, _cameraIdSetting, 0, 0, 0, 0, 0, 0);
    uint8_t buffer[MAVLINK_MAX_PACKET_LEN];
    int len = mavlink_msg_to_send_buffer(buffer, &msg);

    _linkInterface->writeBytesThreadSafe((const char*)buffer, len);

    emit videoNeedsReset();
    qDebug() << "_startVideoStreaming end, cameraId =" << _cameraIdSetting;
}

void VideoStreamControl::_setSettingInProgress(bool inProgress)
{
    if (inProgress) {
        _settingInProgressTimer.setInterval(15000);
        _settingInProgressTimer.setSingleShot(true);
        _settingInProgressTimer.start();
        qCDebug(VideoStreamControlLog) << "Setup timer for setting camera, and lock UI";
    } else {
        if (_settingInProgressTimer.isActive()) {
            _settingInProgressTimer.stop();
            qCDebug(VideoStreamControlLog) << "Done for setting camera, unlock UI and clear timer";
        }
        if (_settingInProgressTimerAck.isActive()) {
            _settingInProgressTimerAck.stop();
            qDebug() << "_settingInProgressTimerAck pushes to stop";
        }
    }

    _settingInProgress = inProgress;
    emit settingInProgressChanged();
    return;
}