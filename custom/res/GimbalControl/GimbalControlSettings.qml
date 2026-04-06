import QtQuick 2.12
import QtQuick.Layouts 1.12
import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Palette 1.0

Item {
    id: root

    readonly property var controller: QGroundControl.corePlugin.gimbalControlController
    property int _editingIndex: -1

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: ScreenTools.defaultFontPixelHeight
        spacing: ScreenTools.defaultFontPixelHeight

        // Header
        QGCLabel {
            text: qsTr("Gimbal Pitch Control Buttons")
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

                    QGCLabel { text: qsTr("Button Label") }
                    QGCTextField {
                        id: labelField
                        Layout.fillWidth: true
                        placeholderText: qsTr("e.g., 'Down 5°' or 'Survey'")
                    }

                    QGCLabel {
                        text: qsTr("Pitch Offset (degrees)")
                        Layout.topMargin: ScreenTools.defaultFontPixelHeight * 0.5
                    }
                    QGCTextField {
                        id: pitchField
                        Layout.fillWidth: true
                        placeholderText: qsTr("e.g., -5 (negative=down, positive=up)")
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                    }

                    QGCLabel {
                        text: qsTr("Range: %1° to %2°").arg(-25).arg(15)
                        font.pointSize: ScreenTools.smallFontPointSize
                        color: qgcPal.colorGrey
                    }

                    Item { Layout.fillHeight: true }  // Spacer

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScreenTools.defaultFontPixelWidth

                        QGCButton {
                            Layout.fillWidth: true
                            text: _editingIndex >= 0 ? qsTr("Update") : qsTr("Add")
                            enabled: labelField.text.length > 0 && pitchField.text.length > 0
                            primary: true
                            onClicked: {
                                const pitch = parseFloat(pitchField.text)
                                if (isNaN(pitch) || pitch < -25 || pitch > 15) {
                                    // TODO: Show error dialog
                                    return
                                }

                                if (_editingIndex >= 0) {
                                    controller.updatePitchButton(_editingIndex, labelField.text, pitch)
                                } else {
                                    controller.addPitchButton(labelField.text, pitch)
                                }

                                labelField.text = ""
                                pitchField.text = ""
                                _editingIndex = -1
                            }
                        }

                        QGCButton {
                            Layout.fillWidth: true
                            text: qsTr("Clear")
                            visible: _editingIndex >= 0 || labelField.text.length > 0
                            onClicked: {
                                labelField.text = ""
                                pitchField.text = ""
                                _editingIndex = -1
                            }
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
                        id: buttonListView
                        anchors.fill: parent
                        anchors.margins: 1
                        model: controller ? controller.pitchButtons : []
                        clip: true
                        spacing: 1

                        delegate: Rectangle {
                            width: buttonListView.width
                            height: buttonLayout.implicitHeight + ScreenTools.defaultFontPixelHeight
                            color: index % 2 === 0 ? qgcPal.window : qgcPal.windowShade

                            RowLayout {
                                id: buttonLayout
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: ScreenTools.defaultFontPixelHeight / 2
                                spacing: ScreenTools.defaultFontPixelWidth

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    QGCLabel {
                                        text: modelData.label
                                        font.bold: true
                                    }
                                    QGCLabel {
                                        text: qsTr("Pitch: %1°").arg(modelData.pitchOffset)
                                        font.pointSize: ScreenTools.smallFontPointSize
                                    }
                                }

                                QGCButton {
                                    text: qsTr("Edit")
                                    onClicked: {
                                        _editingIndex = index
                                        labelField.text = modelData.label
                                        pitchField.text = modelData.pitchOffset
                                    }
                                }

                                QGCButton {
                                    text: qsTr("Delete")
                                    onClicked: controller.removePitchButton(index)
                                }
                            }
                        }

                        QGCLabel {
                            anchors.centerIn: parent
                            text: qsTr("No pitch buttons configured.\nUse the form on the left to add buttons.")
                            horizontalAlignment: Text.AlignHCenter
                            visible: controller ? controller.pitchButtons.length === 0 : true
                        }
                    }
                }
            }
        }
    }
}
