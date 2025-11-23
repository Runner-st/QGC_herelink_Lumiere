/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick                          2.11
import QtQuick.Controls                 2.4

import QGroundControl                   1.0
import QGroundControl.FlightDisplay     1.0
import QGroundControl.FlightMap         1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.Palette           1.0
import QGroundControl.Vehicle           1.0
import QGroundControl.Controllers       1.0

Item {
    id:     root
    clip:   true

    property bool useSmallFont: true

    property double _ar:                QGroundControl.videoManager.aspectRatio
    property bool   _showGrid:          QGroundControl.settingsManager.videoSettings.gridLines.rawValue > 0
    property var    _dynamicCameras:    globals.activeVehicle ? globals.activeVehicle.cameraManager : null
    property bool   _connected:         globals.activeVehicle ? !globals.activeVehicle.communicationLost : false
    property int    _curCameraIndex:    _dynamicCameras ? _dynamicCameras.currentCamera : 0
    property bool   _isCamera:          _dynamicCameras ? _dynamicCameras.cameras.count > 0 : false
    property var    _camera:            _isCamera ? _dynamicCameras.cameras.get(_curCameraIndex) : null
    property bool   _hasZoom:           _camera && _camera.hasZoom
    property int    _fitMode:           QGroundControl.settingsManager.videoSettings.videoFit.rawValue

    function getWidth() {
        return videoBackground.getWidth()
    }
    function getHeight() {
        return videoBackground.getHeight()
    }

    property double _thermalHeightFactor: 0.85 //-- TODO

        Image {
            id:             noVideo
            anchors.fill:   parent
            source:         "/res/NoVideoBackground.jpg"
            fillMode:       Image.PreserveAspectCrop
            visible:        !(QGroundControl.videoManager.decoding)

            Rectangle {
                anchors.centerIn:   parent
                width:              noVideoLabel.contentWidth + ScreenTools.defaultFontPixelHeight
                height:             noVideoLabel.contentHeight + ScreenTools.defaultFontPixelHeight
                radius:             ScreenTools.defaultFontPixelWidth / 2
                color:              "black"
                opacity:            0.5
            }

            QGCLabel {
                id:                 noVideoLabel
                text:               QGroundControl.settingsManager.videoSettings.streamEnabled.rawValue ? qsTr("WAITING FOR VIDEO") : qsTr("VIDEO DISABLED")
                font.family:        ScreenTools.demiboldFontFamily
                color:              "white"
                font.pointSize:     useSmallFont ? ScreenTools.smallFontPointSize : ScreenTools.largeFontPointSize
                anchors.centerIn:   parent
            }
        }

    Rectangle {
        id:             videoBackground
        anchors.fill:   parent
        color:          "black"
        visible:        QGroundControl.videoManager.decoding
        property bool primaryIsMain: true
        property real pipScale: 0.3

        function _pipSize() {
            return Qt.size(parent.width * pipScale, parent.height * pipScale)
        }

        function _resetAnchors(targetItem) {
            targetItem.anchors.fill = undefined
            targetItem.anchors.top = undefined
            targetItem.anchors.bottom = undefined
            targetItem.anchors.left = undefined
            targetItem.anchors.right = undefined
            targetItem.anchors.margins = 0
        }

        function updateSecondaryOpacity() {
            if (secondaryLoader.item) {
                secondaryLoader.item.opacity = _camera ? (_camera.thermalMode === QGCCameraControl.THERMAL_BLEND ? _camera.thermalOpacity / 100 : 1.0) : 1.0
            }
        }

        function updateVideoLayout() {
            var pipSize = _pipSize()
            primaryContainer.isMain = primaryIsMain
            secondaryContainer.isMain = !primaryIsMain

            _resetAnchors(primaryContainer)
            _resetAnchors(secondaryContainer)

            if (primaryIsMain) {
                primaryContainer.anchors.fill = videoBackground
                primaryContainer.z = 1

                secondaryContainer.width = pipSize.width
                secondaryContainer.height = pipSize.height
                secondaryContainer.anchors.right = videoBackground.right
                secondaryContainer.anchors.bottom = videoBackground.bottom
                secondaryContainer.anchors.margins = ScreenTools.defaultFontPixelWidth
                secondaryContainer.z = 2
            } else {
                secondaryContainer.anchors.fill = videoBackground
                secondaryContainer.z = 1

                primaryContainer.width = pipSize.width
                primaryContainer.height = pipSize.height
                primaryContainer.anchors.right = videoBackground.right
                primaryContainer.anchors.bottom = videoBackground.bottom
                primaryContainer.anchors.margins = ScreenTools.defaultFontPixelWidth
                primaryContainer.z = 2
            }

            primaryLoader.showGrid = primaryContainer.isMain && !QGroundControl.videoManager.fullScreen
            secondaryLoader.showGrid = secondaryContainer.isMain && !QGroundControl.videoManager.fullScreen
        }
        function getWidth() {
            //-- Fit Width or Stretch
            if(_fitMode === 0 || _fitMode === 2) {
                return parent.width
            }
            //-- Fit Height
            return _ar != 0.0 ? parent.height * _ar : parent.width
        }
        function getHeight() {
            //-- Fit Height or Stretch
            if(_fitMode === 1 || _fitMode === 2) {
                return parent.height
            }
            //-- Fit Width
            return _ar != 0.0 ? parent.width * (1 / _ar) : parent.height
        }
        Component {
            id: videoBackgroundComponent
            QGCVideoBackground {
                id:             videoContent
                property bool showGrid: false
                objectName:     "videoContent"

                Connections {
                    target: QGroundControl.videoManager
                    function onImageFileChanged() {
                        videoContent.grabToImage(function(result) {
                            if (!result.saveToFile(QGroundControl.videoManager.imageFile)) {
                                console.error('Error capturing video frame');
                            }
                        });
                    }
                }
                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    height: parent.height
                    width:  1
                    x:      parent.width * 0.33
                    visible: _showGrid && videoContent.showGrid
                }
                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    height: parent.height
                    width:  1
                    x:      parent.width * 0.66
                    visible: _showGrid && videoContent.showGrid
                }
                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    width:  parent.width
                    height: 1
                    y:      parent.height * 0.33
                    visible: _showGrid && videoContent.showGrid
                }
                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    width:  parent.width
                    height: 1
                    y:      parent.height * 0.66
                    visible: _showGrid && videoContent.showGrid
                }
            }
        }
        Item {
            id:                     primaryContainer
            property bool isMain:   true
            width:                  parent.width
            height:                 parent.height

            Loader {
                id:                 primaryLoader
                anchors.fill:       parent
                active:             QGroundControl.videoManager.decoding
                sourceComponent:    videoBackgroundComponent
                property bool showGrid: parent.isMain && !QGroundControl.videoManager.fullScreen
                onLoaded: {
                    item.objectName = "videoContent"
                    item.showGrid = showGrid
                }
                onShowGridChanged: if (item) { item.showGrid = showGrid }
            }

            Rectangle {
                anchors.fill:   parent
                color:          "transparent"
                border.color:   "white"
                border.width:   ScreenTools.defaultFontPixelWidth / 2
                radius:         ScreenTools.defaultFontPixelWidth
                visible:        !parent.isMain && QGroundControl.videoManager.secondaryVideoAvailable
            }
        }

        Item {
            id:                     secondaryContainer
            property bool isMain:   false
            visible:                QGroundControl.videoManager.secondaryVideoAvailable && QGroundControl.videoManager.decoding

            Loader {
                id:                 secondaryLoader
                anchors.fill:       parent
                active:             QGroundControl.videoManager.decoding && QGroundControl.videoManager.secondaryVideoAvailable
                sourceComponent:    videoBackgroundComponent
                property bool showGrid: parent.isMain && !QGroundControl.videoManager.fullScreen
                onLoaded: {
                    item.objectName = "thermalVideo"
                    item.showGrid = showGrid
                    videoBackground.updateSecondaryOpacity()
                }
                onShowGridChanged: if (item) { item.showGrid = showGrid }
            }

            Rectangle {
                anchors.fill:   parent
                color:          "transparent"
                border.color:   "white"
                border.width:   ScreenTools.defaultFontPixelWidth / 2
                radius:         ScreenTools.defaultFontPixelWidth
                visible:        !parent.isMain
            }

            MouseArea {
                anchors.fill:   parent
                enabled:        secondaryContainer.visible
                onClicked:      videoBackground.primaryIsMain = !videoBackground.primaryIsMain
            }
        }

        onPrimaryIsMainChanged: updateVideoLayout()
        onWidthChanged:         updateVideoLayout()
        onHeightChanged:        updateVideoLayout()

        Component.onCompleted:  updateVideoLayout()

        Connections {
            target: QGroundControl.videoManager
            onSecondaryVideoChanged: videoBackground.updateVideoLayout()
        }
        Connections {
            target: _camera
            onThermalModeChanged: videoBackground.updateSecondaryOpacity()
            onThermalOpacityChanged: videoBackground.updateSecondaryOpacity()
        }
        //-- Zoom
        PinchArea {
            id:             pinchZoom
            enabled:        _hasZoom
            anchors.fill:   parent
            onPinchStarted: pinchZoom.zoom = 0
            onPinchUpdated: {
                if(_hasZoom) {
                    var z = 0
                    if(pinch.scale < 1) {
                        z = Math.round(pinch.scale * -10)
                    } else {
                        z = Math.round(pinch.scale)
                    }
                    if(pinchZoom.zoom != z) {
                        _camera.stepZoom(z)
                    }
                }
            }
            property int zoom: 0
        }
    }
}
