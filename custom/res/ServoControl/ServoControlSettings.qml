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

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

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
        anchors.fill: parent
        anchors.margins: ScreenTools.defaultFontPixelHeight
        spacing: ScreenTools.defaultFontPixelHeight

        // Header
        QGCLabel {
            text: qsTr("Configure Servo Buttons")
            font.pointSize: ScreenTools.defaultFontPointSize * 1.2
            Layout.fillWidth: true
        }

        // Two-column layout: Form on left, List on right
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: ScreenTools.defaultFontPixelWidth * 2

            // LEFT COLUMN: Add/Edit Form
            QGCGroupBox {
                Layout.preferredWidth: parent.width * 0.4
                Layout.fillHeight: true
                title: _editingIndex >= 0 ? qsTr("Edit Button") : qsTr("Add Button")

                ColumnLayout {
                    anchors.fill: parent
                    spacing: ScreenTools.defaultFontPixelHeight * 0.5

                    QGCLabel { text: qsTr("Button name") }
                    QGCTextField {
                        id: nameField
                        Layout.fillWidth: true
                    }

                    QGCLabel {
                        text: qsTr("Servo output")
                        Layout.topMargin: ScreenTools.defaultFontPixelHeight * 0.5
                    }
                    QGCTextField {
                        id: outputField
                        Layout.fillWidth: true
                        inputMethodHints: Qt.ImhDigitsOnly
                    }

                    QGCLabel {
                        text: qsTr("PWM pulse width (µs)")
                        Layout.topMargin: ScreenTools.defaultFontPixelHeight * 0.5
                    }
                    QGCTextField {
                        id: pwmField
                        Layout.fillWidth: true
                        inputMethodHints: Qt.ImhDigitsOnly
                    }

                    Item { Layout.fillHeight: true }  // Spacer

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScreenTools.defaultFontPixelWidth

                        QGCButton {
                            Layout.fillWidth: true
                            text: _editingIndex >= 0 ? qsTr("Update") : qsTr("Add")
                            enabled: nameField.text.length > 0 && outputField.text.length > 0 && pwmField.text.length > 0
                            primary: true
                            onClicked: saveButton()
                        }

                        QGCButton {
                            Layout.fillWidth: true
                            text: qsTr("Clear")
                            visible: _editingIndex >= 0 || nameField.text.length > 0 || outputField.text.length > 0 || pwmField.text.length > 0
                            onClicked: resetForm()
                        }
                    }
                }
            }

            // RIGHT COLUMN: Configured Buttons List
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: ScreenTools.defaultFontPixelHeight * 0.5

                QGCLabel {
                    text: qsTr("Configured Buttons")
                    font.bold: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: qgcPal.windowShade
                    border.color: qgcPal.text
                    border.width: 1
                    radius: 3

                    ListView {
                        id: listView
                        anchors.fill: parent
                        anchors.margins: 1
                        model: controller ? controller.buttons : []
                        clip: true
                        spacing: 1

                        delegate: Rectangle {
                            width: listView.width
                            height: buttonRow.implicitHeight + ScreenTools.defaultFontPixelHeight
                            color: index % 2 === 0 ? qgcPal.window : qgcPal.windowShade

                            RowLayout {
                                id: buttonRow
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: ScreenTools.defaultFontPixelHeight / 2
                                spacing: ScreenTools.defaultFontPixelWidth

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    QGCLabel {
                                        text: modelData.name
                                        font.bold: true
                                    }
                                    QGCLabel {
                                        text: qsTr("Output %1 • %2 µs").arg(modelData.output).arg(modelData.pwm)
                                        font.pointSize: ScreenTools.smallFontPointSize
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
                            text: qsTr("No servo buttons configured.\nUse the form on the left to add buttons.")
                            horizontalAlignment: Text.AlignHCenter
                            visible: controller ? controller.buttons.length === 0 : true
                        }
                    }
                }
            }
        }
    }
}
