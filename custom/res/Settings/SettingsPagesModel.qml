import QtQuick 2.12
import QGroundControl 1.0

ListModel {
    id: root

    property var sourcePages: QGroundControl.corePlugin.settingsPages

    function rebuild() {
        clear()
        if (!sourcePages) {
            return
        }

        for (var i = 0; i < sourcePages.length; i++) {
            var page = sourcePages[i]
            append({
                title: page.title,
                url: page.url,
                icon: page.icon
            })
        }
    }

    Component.onCompleted: rebuild()
    onSourcePagesChanged: rebuild()
}
