import QtQuick 2.12
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.12

import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.Palette 1.0
import QGroundControl.ScreenTools 1.0

Item {
    id: root

    readonly property var controller: QGroundControl.corePlugin.servoControlController
    property int _editingIndex: -1

    function resetForm() {
        nameField.text = ""
        outputField.text = ""
        pwmField.text = ""
        _editingIndex = -1
    }

    function saveButton() {
        if (!controller) {
            return
        }

        const outputValue = parseInt(outputField.text)
        const pwmValue = parseInt(pwmField.text)

        if (isNaN(outputValue) || isNaN(pwmValue)) {
            return
        }

        if (_editingIndex >= 0) {
            controller.updateButton(_editingIndex, nameField.text, outputValue, pwmValue)
        } else {
            controller.addButton(nameField.text, outputValue, pwmValue)
        }

        resetForm()
    }

    ColumnLayout {
        anchors.margins: ScreenTools.defaultFontPixelHeight
        anchors.fill: parent
        spacing: ScreenTools.defaultFontPixelHeight

        QGCLabel {
            text: qsTr("Configure Servo Buttons")
            font.pointSize: ScreenTools.defaultFontPointSize * 1.2
        }

        QGCGroupBox {
            Layout.fillWidth: true
            title: _editingIndex >= 0 ? qsTr("Edit Button") : qsTr("Add Button")

            ColumnLayout {
                anchors.margins: ScreenTools.defaultFontPixelHeight
                anchors.fill: parent
                spacing: ScreenTools.defaultFontPixelHeight / 2

                QGCLabel { text: qsTr("Button name") }
                QGCTextField {
                    id: nameField
                    Layout.fillWidth: true
                }

                QGCLabel { text: qsTr("Servo output") }
                QGCTextField {
                    id: outputField
                    Layout.fillWidth: true
                    inputMethodHints: Qt.ImhDigitsOnly
                }

                QGCLabel { text: qsTr("PWM pulse width (µs)") }
                QGCTextField {
                    id: pwmField
                    Layout.fillWidth: true
                    inputMethodHints: Qt.ImhDigitsOnly
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScreenTools.defaultFontPixelHeight

                    QGCButton {
                        text: _editingIndex >= 0 ? qsTr("Update") : qsTr("Add")
                        enabled: nameField.text.length > 0 && outputField.text.length > 0 && pwmField.text.length > 0
                        onClicked: saveButton()
                    }

                    QGCButton {
                        text: qsTr("Clear")
                        visible: _editingIndex >= 0 || nameField.text.length > 0 || outputField.text.length > 0 || pwmField.text.length > 0
                        onClicked: resetForm()
                    }
                }
            }
        }

        QGCLabel {
            text: qsTr("Configured buttons")
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0, 0, 0, 0.05)

            ListView {
                id: listView
                anchors.fill: parent
                model: controller ? controller.buttons : []
                clip: true

                delegate: Rectangle {
                    width: listView.width
                    height: Math.max(ScreenTools.defaultFontPixelHeight * 2.5, buttonRow.implicitHeight + ScreenTools.defaultFontPixelHeight)
                    color: index % 2 === 0 ? Qt.rgba(0,0,0,0.02) : Qt.rgba(0,0,0,0)

                    RowLayout {
                        id: buttonRow
                        anchors.fill: parent
                        anchors.margins: ScreenTools.defaultFontPixelHeight / 2
                        spacing: ScreenTools.defaultFontPixelHeight

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: ScreenTools.defaultFontPixelHeight / 4

                            QGCLabel {
                                text: modelData.name
                                font.bold: true
                            }

                            QGCLabel {
                                text: qsTr("Output %1 • %2 µs").arg(modelData.output).arg(modelData.pwm)
                            }
                        }

                        QGCButton {
                            text: qsTr("Edit")
                            onClicked: {
                                _editingIndex = index
                                nameField.text = modelData.name
                                outputField.text = modelData.output
                                pwmField.text = modelData.pwm
                            }
                        }

                        QGCButton {
                            text: qsTr("Delete")
                            onClicked: controller.removeButton(index)
                        }
                    }
                }

                QGCLabel {
                    anchors.centerIn: parent
                    text: qsTr("No servo buttons configured")
                    visible: (controller ? controller.buttons.length === 0 : true)
                }
            }
        }
    }
}
