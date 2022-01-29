import Felgo 3.0
import QtQuick 2.0

App {
    id: app

    screenWidth: 720
    screenHeight: 1280

    property bool revisionMode: false

    VocabStorage {
        id: vocabStorage
        quizLength: 10
        learnedWords: 20
    }

    NavigationStack {
        id: navigationStack
        Component.onCompleted: {
            navigationStack.push(titlePageComponent)
        }
    }

    Component {
        id: titlePageComponent
        Page {
            id: titlePage
            Column {
                anchors.centerIn: parent
                AppButton {
                    text: "Start"
                    onClicked: {
                        revisionMode = false
                        navigationStack.push(flashDeckComponent)
                    }
                }
                AppButton {
                    text: "Review"
                    onClicked: {
                        revisionMode = true
                        navigationStack.push(flashDeckComponent)
                    }
                }
                AppButton {
                    text: "vocab"
                    onClicked: {
                        navigationStack.push(vocabList)
                    }
                }
            }
        }
    }

    Component {
        id: flashDeckComponent
        FlashDeck {
            id: flashDeck
            Component.onCompleted: {
                if (app.revisionMode) {
                    flashDeck.questions = vocabStorage.selectCardsForRevision()
                } else {
                    flashDeck.questions = vocabStorage.selectCardsForQuiz()
                }
            }
        }
    }

    Component {
        id: vocabList
        VocabList {
            vocab: vocabStorage.vocab
        }
    }
}
