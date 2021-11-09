import QtQuick 2.0
import Felgo 3.0

Page {
    id: vocabList
    title: "Vocab"
    property var vocab: []
    AppFlickable {
        anchors.fill: parent
        anchors.topMargin: 30
        anchors.bottomMargin: 30
        contentWidth: parent.width
        contentHeight: content.height
        Column {
            id: content
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 30
            Repeater {
                id: questionRepeater
                model: vocabList.vocab
                Column {
                    spacing: content.spacing
                    anchors.horizontalCenter: parent.horizontalCenter
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5
                        AppText {
                            id: question
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.Cantonese.join('')
                        }
                        AppText {
                            id: answer
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.English.join('')
                        }
                    }
                    Rectangle {
                        anchors.topMargin: 100
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: vocabList.width * 0.5
                        height: 2
                        color: "#aaa"
                    }
                }
            }
        }
    }
}
