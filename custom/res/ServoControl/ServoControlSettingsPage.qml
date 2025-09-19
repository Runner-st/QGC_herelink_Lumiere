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
import QGroundControl.ScreenTools
import "qrc:/qml/QGroundControl/AppSettings"

SettingsPage {
    id: root

    readonly property var controller: QGroundControl.corePlugin.servoControlController

    property int editingIndex: -1

    function _clearValidation() {
        nameField.clearValidationError()
        servoField.clearValidationError()
        pulseField.clearValidationError()
    }

    function _resetForm() {
        _clearValidation()
        editingIndex = -1
        nameField.text = ""
        servoField.text = ""
        pulseField.text = ""
        nameField.focus = false
        servoField.focus = false
        pulseField.focus = false
    }

    function _validateForm() {
        _clearValidation()

        const trimmedName = nameField.text.trim()
        if (!trimmedName.length) {
            nameField.showValidationError(qsTr("Enter a button name."))
            nameField.focus = true
            return null
        }

        const servoValue = parseInt(servoField.text)
        if (isNaN(servoValue)) {
            servoField.showValidationError(qsTr("Enter a servo output number."))
            servoField.focus = true
            return null
        }
        if (servoValue < 1 || servoValue > 32) {
            servoField.showValidationError(qsTr("Servo output must be between 1 and 32."))
            servoField.focus = true
            return null
        }

        const pulseValue = parseInt(pulseField.text)
        if (isNaN(pulseValue)) {
            pulseField.showValidationError(qsTr("Enter a PWM pulse width in microseconds."))
            pulseField.focus = true
            return null
        }
        if (pulseValue < 500 || pulseValue > 2500) {
            pulseField.showValidationError(qsTr("PWM pulse width must be between 500 and 2500 µs."))
            pulseField.focus = true
            return null
        }

        return {
            name: trimmedName,
            servoOutput: servoValue,
            pulseWidth: pulseValue
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth: true
        heading: qsTr("Servo Control Buttons")
        headingDescription: qsTr("Configure quick access buttons that command servos from the flight controller.")

        ColumnLayout {
            Layout.fillWidth: true
            spacing: ScreenTools.defaultFontPixelHeight

            QGCLabel {
                Layout.fillWidth: true
                text: editingIndex === -1 ? qsTr("Create a new button") : qsTr("Edit button %1").arg(editingIndex + 1)
                font.bold: true
            }

            QGCLabel {
                Layout.fillWidth: true
                text: qsTr("Button name")
            }

            QGCTextField {
                id: nameField
                Layout.fillWidth: true
                placeholderText: qsTr("Example: Drop payload")
            }

            QGCLabel {
                Layout.fillWidth: true
                text: qsTr("Servo output")
            }

            QGCTextField {
                id: servoField
                Layout.fillWidth: true
                inputMethodHints: Qt.ImhDigitsOnly
                placeholderText: qsTr("Servo channel (1-32)")
            }

            QGCLabel {
                Layout.fillWidth: true
                text: qsTr("PWM pulse width (µs)")
            }

            QGCTextField {
                id: pulseField
                Layout.fillWidth: true
                inputMethodHints: Qt.ImhDigitsOnly
                placeholderText: qsTr("Typical range 1000-2000")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth

                QGCButton {
                    Layout.preferredWidth: implicitWidth
                    text: editingIndex === -1 ? qsTr("Add Button") : qsTr("Save Changes")
                    enabled: !!controller

                    onClicked: {
                        if (!controller) {
                            return
                        }
                        const result = _validateForm()
                        if (!result) {
                            return
                        }
                        if (editingIndex === -1) {
                            controller.addButton(result.name, result.servoOutput, result.pulseWidth)
                        } else {
                            controller.updateButton(editingIndex, result.name, result.servoOutput, result.pulseWidth)
                        }
                        _resetForm()
                    }
                }

                QGCButton {
                    visible: editingIndex !== -1
                    text: qsTr("Cancel")
                    onClicked: _resetForm()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: controller && controller.buttons && controller.buttons.length > 0

            QGCLabel {
                Layout.fillWidth: true
                text: qsTr("Configured buttons")
                font.bold: true
            }

            Repeater {
                model: controller && controller.buttons ? controller.buttons : []

                delegate: Rectangle {
                    Layout.fillWidth: true
                    color: "transparent"
                    border.width: 1
                    border.color: QGroundControl.globalPalette.groupBorder
                    radius: ScreenTools.defaultFontPixelHeight / 3

                    readonly property real contentMargin: ScreenTools.defaultFontPixelHeight / 2

                    implicitHeight: contentColumn.implicitHeight + (contentMargin * 2)

                    ColumnLayout {
                        id: contentColumn
                        anchors {
                            fill: parent
                            margins: contentMargin
                        }
                        spacing: ScreenTools.defaultFontPixelHeight / 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: ScreenTools.defaultFontPixelWidth

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: ScreenTools.defaultFontPixelHeight / 4

                                QGCLabel {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.bold: true
                                }

                                QGCLabel {
                                    Layout.fillWidth: true
                                    text: qsTr("Servo %1 • %2 µs").arg(modelData.servoOutput).arg(modelData.pulseWidth)
                                    font.pointSize: ScreenTools.smallFontPointSize
                                    color: QGroundControl.globalPalette.textDisabled
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                            }

                            ColumnLayout {
                                spacing: ScreenTools.defaultFontPixelHeight / 4
                                Layout.alignment: Qt.AlignRight | Qt.AlignTop

                                QGCButton {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: implicitWidth
                                    text: qsTr("Edit")
                                    onClicked: {
                                        editingIndex = index
                                        nameField.text = modelData.name
                                        servoField.text = modelData.servoOutput
                                        pulseField.text = modelData.pulseWidth
                                        _clearValidation()
                                    }
                                }

                                QGCButton {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: implicitWidth
                                    text: qsTr("Delete")
                                    onClicked: {
                                        if (controller) {
                                            controller.removeButton(index)
                                        }
                                        if (editingIndex === index) {
                                            _resetForm()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
