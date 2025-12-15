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
    property bool _urlsInitialized: false
    property bool _isSwitchingStream: false  // Flag to prevent feedback loops

    // Stream button label - shows which stream is CURRENTLY ACTIVE
    property string _streamButtonLabel: "Stream1"

    // Initialize on component completion
    Component.onCompleted: {
        if (_videoSettings) {
            _urlsInitialized = true
            console.log("[C12] Stream switcher initialized")
            console.log("[C12] URL1:", _videoSettings.rtspUrl.rawValue)
            console.log("[C12] URL2:", _videoSettings.rtspUrl2.rawValue)
        }
    }

    // Function to toggle between RTSP streams by SWAPPING the URL values
    function toggleRtspStream() {
        if (!_videoSettings || !_urlsInitialized) return

        _isSwitchingStream = true  // Prevent feedback loop

        console.log("[C12] Switching to RTSP video source")

        // First, ensure we're in RTSP video source mode
        var currentSource = _videoSettings.videoSource.rawValue
        var rtspSource = _videoSettings.rtspVideoSource  // "RTSP Video Stream"

        if (currentSource !== rtspSource) {
            console.log("[C12] Changing video source from", currentSource, "to", rtspSource)
            _videoSettings.videoSource.rawValue = rtspSource
        }

        // Get current URLs
        var url1 = _videoSettings.rtspUrl.rawValue
        var url2 = _videoSettings.rtspUrl2.rawValue

        // Swap them
        _videoSettings.rtspUrl.rawValue = url2
        _videoSettings.rtspUrl2.rawValue = url1

        // Update button label
        if (_streamButtonLabel === "Stream1") {
            _streamButtonLabel = "Stream2"
            console.log("[C12] Switched to Stream 2:", url2)
        } else {
            _streamButtonLabel = "Stream1"
            console.log("[C12] Switched to Stream 1:", url2)
        }

        _isSwitchingStream = false
    }

    // Function to switch to HDMI2
    function switchToHdmi2() {
        if (QGroundControl.corePlugin.isHerelink && _videoSettings) {
            console.log("[C12] Switching to HDMI2 (camera ID 1)")
            console.log("[C12] Current video source:", _videoSettings.videoSource.rawValue)
            console.log("[C12] Current camera ID:", _videoSettings.cameraId.rawValue)

            // Determine the correct Herelink video source
            // Use Herelink AirUnit for HDMI passthrough
            var herelinkSource = "Herelink AirUnit"
            var currentSource = _videoSettings.videoSource.rawValue

            // Always set the video source to force a refresh
            console.log("[C12] Setting video source from", currentSource, "to", herelinkSource)
            _videoSettings.videoSource.rawValue = herelinkSource

            // Force a camera ID change by setting to a different value first if already at target
            if (_videoSettings.cameraId.rawValue === 1) {
                console.log("[C12] Camera ID already 1, forcing change by toggling to 0 first")
                _videoSettings.cameraId.rawValue = 0
            }

            _videoSettings.cameraId.rawValue = 1  // HDMI2 is camera ID 1
            console.log("[C12] Camera ID set to:", _videoSettings.cameraId.rawValue)
        } else {
            console.log("[C12] Cannot switch to HDMI2 - isHerelink:", QGroundControl.corePlugin.isHerelink, "videoSettings:", _videoSettings)
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
                    enabled:                _urlsInitialized && _videoSettings &&
                                          (_videoSettings.rtspUrl.rawValue !== "" || _videoSettings.rtspUrl2.rawValue !== "")
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
