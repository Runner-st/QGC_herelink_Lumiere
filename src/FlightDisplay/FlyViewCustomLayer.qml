/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 * Custom layer with C12 Camera Controls for Skydroid C12
 *
 ****************************************************************************/

import QtQuick                  2.12
import QtQuick.Controls         2.4
import QtQuick.Dialogs          1.3
import QtQuick.Layouts          1.12
import QtLocation               5.3
import QtPositioning            5.3
import QtQuick.Window           2.2
import QtQml.Models             2.1

import QGroundControl               1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

Item {
    id: _root

    property var parentToolInsets
    property var totalToolInsets:   _toolInsets
    property var mapControl

    property var _activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property var _videoSettings:    QGroundControl.settingsManager.videoSettings
    property int _currentStreamIndex: 0  // 0: Stream1, 1: Stream2

    // Store the original RTSP URLs to preserve them during switching
    property string _storedRtspUrl1: ""
    property string _storedRtspUrl2: ""
    property bool _urlsInitialized: false

    // Stream button labels
    property string _streamButtonLabel: _currentStreamIndex === 0 ? qsTr("Stream1") : qsTr("Stream2")

    // Initialize stored URLs on component completion
    Component.onCompleted: {
        if (_videoSettings) {
            _storedRtspUrl1 = _videoSettings.rtspUrl.rawValue
            _storedRtspUrl2 = _videoSettings.rtspUrl2.rawValue
            _urlsInitialized = true
        }
    }

    // Function to toggle between RTSP streams
    function toggleRtspStream() {
        if (!_videoSettings || !_urlsInitialized) return

        if (_currentStreamIndex === 0) {
            // Switch to Stream2
            if (_storedRtspUrl2 !== "") {
                _videoSettings.rtspUrl.rawValue = _storedRtspUrl2
                _currentStreamIndex = 1
            }
        } else {
            // Switch back to Stream1
            if (_storedRtspUrl1 !== "") {
                _videoSettings.rtspUrl.rawValue = _storedRtspUrl1
                _currentStreamIndex = 0
            }
        }
    }

    // Function to switch to HDMI2
    function switchToHdmi2() {
        if (QGroundControl.corePlugin.isHerelink && _videoSettings) {
            _videoSettings.cameraId.rawValue = 1  // HDMI2 is camera ID 1
        }
    }

// Tool insets - inform the system about space used by our custom controls
    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      c12CameraControl.visible ? c12CameraControl.height + ScreenTools.defaultFontPixelHeight * 9 : parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      c12CameraControl.visible ? c12CameraControl.width + ScreenTools.defaultFontPixelWidth * 2 : parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }

    // C12 Camera Controller instance
    CustomC12Controller {
        id: c12Controller
    }

// C12 Camera Control Panel
    Rectangle {
        id:             c12CameraControl
        anchors.right:  parent.right          // Changed to right side
        anchors.top:    parent.top            // Changed to top
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
        anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 6  // Leave space for instruments
        
        width:          mainLayout.width + (ScreenTools.defaultFontPixelWidth * 2)
        height:         mainLayout.height + (ScreenTools.defaultFontPixelHeight * 1.5)
        
        radius:         ScreenTools.defaultFontPixelWidth * 0.5
        color:          qgcPal.window
        border.color:   qgcPal.text
        border.width:   1
        opacity:        0.75                   // More opaque (was 0.95)
        visible:        _activeVehicle
        
        property var qgcPal: QGroundControl.globalPalette

        ColumnLayout {
            id:                 mainLayout
            anchors.centerIn:   parent
            spacing:            ScreenTools.defaultFontPixelHeight * 0.3  // Tighter spacing

            // Stream Switching Controls Row
            RowLayout {
                spacing:            ScreenTools.defaultFontPixelWidth * 0.5
                Layout.alignment:   Qt.AlignHCenter

                QGCButton {
                    id:                     rtspStreamButton
                    text:                   _streamButtonLabel
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 11
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2
                    onClicked:              toggleRtspStream()
                    enabled:                _urlsInitialized && (_storedRtspUrl1 !== "" || _storedRtspUrl2 !== "")
                }

                QGCButton {
                    id:                     hdmi2Button
                    text:                   qsTr("HDMI2")
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 11
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2
                    onClicked:              switchToHdmi2()
                    enabled:                QGroundControl.corePlugin.isHerelink
                }
            }

            // Center Controls Row
            RowLayout {
                spacing:            ScreenTools.defaultFontPixelWidth * 0.5
                Layout.alignment:   Qt.AlignHCenter

                QGCButton {
                    text:                   "Center"
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 11
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2
                    onClicked:              c12Controller.centerCamera()
                }

                QGCButton {
                    text:                   "Tilt"
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 11
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2
                    onClicked:              c12Controller.centerTiltOnly()
                }
            }

            // Zoom Controls Row
            RowLayout {
                spacing:            ScreenTools.defaultFontPixelWidth * 0.5
                Layout.alignment:   Qt.AlignHCenter

                QGCButton {
                    text:                   "Zoom -"
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 10
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.5
                    onClicked:              c12Controller.zoomOut()
                    
                    // Auto-repeat when button is held down
                    property bool isHeld: false
                    
                    Timer {
                        id:         zoomOutTimer
                        interval:   200
                        repeat:     true
                        running:    parent.isHeld
                        onTriggered: c12Controller.zoomOut()
                    }
                    
                    onPressedChanged: isHeld = pressed
                }

                QGCButton {
                    text:                   "Zoom +"
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 10
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.5
                    onClicked:              c12Controller.zoomIn()
                    
                    // Auto-repeat when button is held down
                    property bool isHeld: false
                    
                    Timer {
                        id:         zoomInTimer
                        interval:   200
                        repeat:     true
                        running:    parent.isHeld
                        onTriggered: c12Controller.zoomIn()
                    }
                    
                    onPressedChanged: isHeld = pressed
                }
            }
        }

        // Visual feedback on mouse hover
        MouseArea {
            anchors.fill:           parent
            hoverEnabled:           true
            propagateComposedEvents: true
            
            onEntered: parent.opacity = 0.85
            onExited:  parent.opacity = 0.75
            
            onPressed: mouse.accepted = false
        }
    }
}
