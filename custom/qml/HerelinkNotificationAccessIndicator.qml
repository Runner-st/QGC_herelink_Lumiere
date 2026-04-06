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
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import QGroundControl.Herelink              1.0

//-------------------------------------------------------------------------
//-- Notification Access Indicator: shown when notification listener is not enabled
Item {
    id:             _root
    width:          indicatorRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: !HerelinkTelemetry.notificationAccessGranted

    QGCPalette { id: qgcPal }

    Row {
        id:                     indicatorRow
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width:                  indicatorLabel.width + ScreenTools.defaultFontPixelWidth * 2
            height:                 indicatorLabel.height + ScreenTools.defaultFontPixelHeight * 0.5
            radius:                 ScreenTools.defaultFontPixelHeight * 0.25
            color:                  qgcPal.colorOrange

            QGCLabel {
                id:                     indicatorLabel
                anchors.centerIn:       parent
                text:                   qsTr("Indicators")
                color:                  "white"
                font.pointSize:         ScreenTools.mediumFontPointSize
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked:    HerelinkTelemetry.openNotificationSettings()
    }
}
