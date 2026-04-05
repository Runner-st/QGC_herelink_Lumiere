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

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.Herelink      1.0

//-------------------------------------------------------------------------
//-- Herelink Controller Signal Indicator
Item {
    id:             _root
    width:          rowLayout.width * 1.1
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: HerelinkTelemetry.available

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
                    text:           qsTr("Herelink Controller Signal")
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                GridLayout {
                    columns:        2
                    columnSpacing:  ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter: parent.horizontalCenter

                    QGCLabel { text: qsTr("Pair state:") }
                    QGCLabel { text: HerelinkTelemetry.pairState }

                    QGCLabel { text: qsTr("Main:") }
                    QGCLabel { text: HerelinkTelemetry.controllerSignalMain + " dBm" }

                    QGCLabel { text: qsTr("Secondary:") }
                    QGCLabel { text: HerelinkTelemetry.controllerSignalSecondary + " dBm" }

                    QGCLabel { text: qsTr("Uplink Rate:") }
                    QGCLabel { text: HerelinkTelemetry.uplinkRate + " kbps" }

                    QGCLabel { text: qsTr("Uplink Bandwidth:") }
                    QGCLabel { text: HerelinkTelemetry.uplinkBandwidth + " kbps" }
                }
            }
        }
    }

    Row {
        id:             rowLayout
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth

        QGCColoredImage {
            width:              height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            sourceSize.height:  height
            source:             "/qmlimages/RC.svg"
            fillMode:           Image.PreserveAspectFit
            color:              qgcPal.buttonText
        }

        QGCLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: "M:" + HerelinkTelemetry.controllerSignalMain + " / S:" + HerelinkTelemetry.controllerSignalSecondary + " dBm"
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked:    mainWindow.showIndicatorPopup(_root, popup)
    }
}
