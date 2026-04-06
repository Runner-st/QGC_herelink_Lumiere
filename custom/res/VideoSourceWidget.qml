/****************************************************************************
 *
 * Lumiere Herelink QGC - Video Source Indicator Widget
 * Shows the active video source and provides a quick-switch button.
 *
 ****************************************************************************/

import QtQuick          2.12
import QtQuick.Layouts  1.12

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0

Item {
    id: _root

    width:  _col.width  + _pad * 2
    height: _col.height + _pad * 2

    readonly property real   _pad:          ScreenTools.defaultFontPixelWidth * 0.75
    readonly property color  _neonGreen:    "#39FF14"
    readonly property color  _red:          "#EE3333"
    readonly property string _herelinkSrc:  "Herelink AirUnit"

    property var    _videoSettings: QGroundControl.settingsManager.videoSettings
    property string _videoSource:   _videoSettings.videoSource.rawValue
    property bool   _isHerelink:    _videoSource === _herelinkSrc
    property bool   _isRTSP:        _videoSource === _videoSettings.rtspVideoSource
    property bool   _connected:     QGroundControl.videoManager.decoding || QGroundControl.videoManager.streaming

    QGCPalette { id: qgcPal }

    // Semi-transparent dark background
    Rectangle {
        anchors.fill: parent
        radius:       ScreenTools.defaultFontPixelHeight * 0.5
        color:        Qt.rgba(0, 0, 0, 0.55)
    }

    Column {
        id:             _col
        anchors.centerIn: parent
        spacing:        ScreenTools.defaultFontPixelHeight * 0.35

        // Indicator: circle + label
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing:                  ScreenTools.defaultFontPixelWidth * 0.5

            Rectangle {
                width:                  ScreenTools.defaultFontPixelHeight * 0.8
                height:                 width
                radius:                 width / 2
                anchors.verticalCenter: parent.verticalCenter
                color:                  _root._connected ? _root._neonGreen : _root._red
            }

            QGCLabel {
                text:                   _root._isHerelink ? qsTr("Herelink") : (_root._isRTSP ? qsTr("RTSP") : _root._videoSource)
                color:                  "white"
                font.bold:              true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Quick-switch button
        QGCButton {
            text:                     "Змінити"
            anchors.horizontalCenter: parent.horizontalCenter

            onClicked: {
                if (_root._isHerelink) {
                    QGroundControl.videoManager.stopVideo()
                    _root._videoSettings.videoSource.rawValue = _root._videoSettings.rtspVideoSource
                    globals.scrollToVideoSettings = true
                    mainWindow.showSettingsTool()
                } else if (_root._isRTSP) {
                    QGroundControl.videoManager.stopVideo()
                    _root._videoSettings.videoSource.rawValue = _root._herelinkSrc
                }
            }
        }
    }
}
