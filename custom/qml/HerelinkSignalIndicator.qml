/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import QGroundControl.Herelink              1.0

//-------------------------------------------------------------------------
//-- Herelink Signal Indicator (Controller + Air stacked in two rows)
Item {
    id:             _root
    width:          mainRow.width * 1.1
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property var  _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property bool showIndicator:  HerelinkTelemetry.available && _activeVehicle

    Component {
        id: popup

        Rectangle {
            width:          col.width  + ScreenTools.defaultFontPixelWidth  * 3
            height:         col.height + ScreenTools.defaultFontPixelHeight * 2
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            color:          qgcPal.window
            border.color:   qgcPal.text

            Column {
                id:                 col
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent

                QGCLabel {
                    text:           qsTr("Herelink Signal Status")
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                GridLayout {
                    columns:        2
                    columnSpacing:  ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter: parent.horizontalCenter

                    QGCLabel { text: qsTr("Pair state:") }
                    QGCLabel { text: HerelinkTelemetry.pairState }

                    QGCLabel { text: qsTr("Ctrl Main:") }
                    QGCLabel { text: HerelinkTelemetry.controllerSignalMain + " dBm" }

                    QGCLabel { text: qsTr("Ctrl Secondary:") }
                    QGCLabel { text: HerelinkTelemetry.controllerSignalSecondary + " dBm" }

                    QGCLabel { text: qsTr("Air Main:") }
                    QGCLabel { text: HerelinkTelemetry.airSignalMain + " dBm" }

                    QGCLabel { text: qsTr("Air Secondary:") }
                    QGCLabel { text: HerelinkTelemetry.airSignalSecondary + " dBm" }

                    QGCLabel { text: qsTr("Uplink Rate:") }
                    QGCLabel { text: HerelinkTelemetry.uplinkRate + " kbps" }

                    QGCLabel { text: qsTr("Uplink Bandwidth:") }
                    QGCLabel { text: HerelinkTelemetry.uplinkBandwidth + " kbps" }
                }
            }
        }
    }

    Row {
        id:                     mainRow
        anchors.verticalCenter: parent.verticalCenter
        spacing:                ScreenTools.defaultFontPixelWidth * 0.5

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing:    1

            Row {
                spacing: ScreenTools.defaultFontPixelWidth * 0.5
                QGCColoredImage {
                    width:              height
                    height:             ctrlLabel.height
                    sourceSize.height:  height
                    source:             "/qmlimages/RC.svg"
                    fillMode:           Image.PreserveAspectFit
                    color:              qgcPal.buttonText
                    anchors.verticalCenter: parent.verticalCenter
                }
                QGCLabel {
                    id:             ctrlLabel
                    font.pointSize: ScreenTools.mediumFontPointSize
                    text:           HerelinkTelemetry.controllerSignalMain + " / " + HerelinkTelemetry.controllerSignalSecondary + " dBm"
                }
            }

            Row {
                spacing: ScreenTools.defaultFontPixelWidth * 0.5
                QGCColoredImage {
                    width:              height
                    height:             airLabel.height
                    sourceSize.height:  height
                    source:             "/qmlimages/TelemRSSI.svg"
                    fillMode:           Image.PreserveAspectFit
                    color:              qgcPal.buttonText
                    anchors.verticalCenter: parent.verticalCenter
                }
                QGCLabel {
                    id:             airLabel
                    font.pointSize: ScreenTools.mediumFontPointSize
                    text:           HerelinkTelemetry.airSignalMain + " / " + HerelinkTelemetry.airSignalSecondary + " dBm"
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked:    mainWindow.showIndicatorPopup(_root, popup)
    }
}
