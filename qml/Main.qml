import Felgo 3.0
import QtQuick 2.0

App {
    screenWidth: 720
    screenHeight: 1280

    VocabStorage {
        id: vocabStorage
        quizLength: 10
        learnedWords: 20
    }

    NavigationStack {
        id: navigationStack
        Component.onCompleted: {
            vocabStorage.parseJson("../assets/vocab.json")
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
                flashDeck.questions = vocabStorage.selectCardsForQuiz()
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
