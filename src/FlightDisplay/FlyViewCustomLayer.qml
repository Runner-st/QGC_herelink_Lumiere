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

    // Tool insets - inform the system about space used by our custom controls
    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    c12CameraControl.visible ? c12CameraControl.height + ScreenTools.defaultFontPixelHeight * 3 : parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    c12CameraControl.visible ? c12CameraControl.width + ScreenTools.defaultFontPixelWidth * 2 : parentToolInsets.bottomEdgeLeftInset
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
        anchors.left:   parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
        anchors.bottomMargin:   ScreenTools.defaultFontPixelHeight * 2
        
        width:          mainLayout.width + (ScreenTools.defaultFontPixelWidth * 3)
        height:         mainLayout.height + (ScreenTools.defaultFontPixelHeight * 2)
        
        radius:         ScreenTools.defaultFontPixelWidth * 0.5
        color:          qgcPal.window
        border.color:   qgcPal.text
        border.width:   1
        opacity:        0.95
        visible:        _activeVehicle
        
        property var qgcPal: QGroundControl.globalPalette

        ColumnLayout {
            id:                 mainLayout
            anchors.centerIn:   parent
            spacing:            ScreenTools.defaultFontPixelHeight * 0.5

            // Title
            QGCLabel {
                text:                   "C12 Camera"
                font.pointSize:         ScreenTools.mediumFontPointSize
                font.bold:              true
                Layout.alignment:       Qt.AlignHCenter
                color:                  qgcPal.text
            }

            // Separator line
            Rectangle {
                Layout.fillWidth:       true
                Layout.preferredHeight: 1
                color:                  qgcPal.text
                opacity:                0.3
            }

            // Center Controls Row
            RowLayout {
                spacing:            ScreenTools.defaultFontPixelWidth * 0.5
                Layout.alignment:   Qt.AlignHCenter

                QGCButton {
                    text:                   "Center All"
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 11
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2
                    onClicked:              c12Controller.centerCamera()
                }

                QGCButton {
                    text:                   "Center Tilt"
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
                        interval:   200  // Send command every 200ms while held
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
                        interval:   200  // Send command every 200ms while held
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
            
            onEntered: parent.opacity = 1.0
            onExited:  parent.opacity = 0.95
            
            // Allow clicks to pass through to buttons
            onPressed: mouse.accepted = false
        }
    }
}
