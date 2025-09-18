/****************************************************************************
 *
 * (c) 2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

Item {
    id: _root

    property var parentToolInsets               // These insets tell you what screen real estate is available for positioning the controls in your overlay
    property var totalToolInsets:   _toolInsets // These are the insets for your custom overlay additions
    property var mapControl

    readonly property var controller: QGroundControl.corePlugin.servoControlController

    readonly property real _buttonMargin: ScreenTools.defaultFontPixelWidth

    Column {
        id: servoButtonColumn
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: _buttonMargin
        anchors.bottomMargin: ScreenTools.defaultFontPixelHeight
        spacing: ScreenTools.defaultFontPixelHeight / 2
        visible: controller && controller.buttons.length > 0

        Repeater {
            model: controller ? controller.buttons : []

            delegate: QGCButton {
                text: modelData.name
                checkable: true
                checked: controller && controller.activeButtonIndex === index
                primary: checked
                onClicked: controller.triggerButton(index)
                enabled: QGroundControl.multiVehicleManager.activeVehicle !== null

                ToolTip.visible: hovered
                ToolTip.delay: 0
                ToolTip.text: qsTr("Servo %1 • %2 µs").arg(modelData.servoOutput).arg(modelData.pulseWidth)
            }
        }
    }

    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    Math.max(parentToolInsets.leftEdgeBottomInset, servoButtonColumn.visible ? servoButtonColumn.width + (_buttonMargin * 2) : parentToolInsets.leftEdgeBottomInset)
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    Math.max(parentToolInsets.bottomEdgeLeftInset, servoButtonColumn.visible ? servoButtonColumn.height + (servoButtonColumn.anchors.bottomMargin * 2) : parentToolInsets.bottomEdgeLeftInset)
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }
}
