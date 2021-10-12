import Felgo 3.0
import QtQuick 2.0

App {
    property var vocab: []
    property var quizLength: 10
    screenWidth: 720
    screenHeight: 1280

    NavigationStack {
        id: navigationStack
        Component.onCompleted: {
            parseJson("../assets/vocab.json")
            navigationStack.push(titlePageComponent)
        }
    }

    Component {
        id: titlePageComponent
        Page {
            id: titlePage
            AppButton {
                text: "Start"
                anchors.centerIn: parent
                onClicked: {
                    navigationStack.push(flashDeckComponent)
                }
            }
        }
    }

    Component {
        id: flashDeckComponent
        Page {
            id: flashDeck
            property int deckIdx: 0
            property var questions: []
            title: "Quiz"
            Component.onCompleted: {
                questions = selectCardsForQuiz()
            }
            Repeater {
                id: repeater
                model: flashDeck.questions
                Item {
                    id: flashCard
                    property bool submittedAnswer: false
                    property bool correct: false
                    property bool promptIsCantonese: index%2 === 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -200
                    visible: index === flashDeck.deckIdx
                    AppText {
                        id: prompt
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: flashCard.promptIsCantonese ? modelData.Cantonese : modelData.English
                    }
                    AppTextEdit {
                        id: placeHolderText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "answer"
                        visible: false // just used to set the placeholder text width
                    }
                    AppTextEdit {
                        id: userResponse
                        visible: !submittedAnswer
                        anchors.top: prompt.bottom
                        anchors.topMargin: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: text === "" ? placeHolderText.paintedWidth : flashDeckComponent.width //userResponseSubmitted.paintedWidth
                        placeholderText: focus ? "" : "answer"
                        horizontalAlignment: TextEdit.AlignHCenter
                        Keys.onReturnPressed: {
                            focus = false
                            flashCard.checkAnswer()
                        }
                    }
                    AppText {
                        id: userResponseSubmitted
                        visible: submittedAnswer
                        anchors.top: prompt.bottom
                        anchors.topMargin: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: flashCard.correct ? correctAnswer.text : userResponse.text
                        color: flashCard.correct ? "green" : "red"
                    }
                    AppText {
                        id: correctAnswer
                        anchors.top: userResponse.bottom
                        anchors.topMargin: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: flashCard.promptIsCantonese ? modelData.English : modelData.Cantonese
                        visible: flashCard.submittedAnswer && !flashCard.correct
                    }
                    AppButton {
                        id: nextCardButton
                        anchors.top: correctAnswer.bottom
                        anchors.topMargin: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: flashCard.submittedAnswer
                        text: index === quizLength - 1 ? "finish" : "next"
                        onClicked: flashCard.nextQuestionOrReturnToMenu(index)
                    }

                    function checkAnswer() {
                        flashCard.submittedAnswer = true
                        var userResponseWithoutNumbers = userResponse.text.replace(/[0-9]/g, '').replace(/[.,\/#!$%\^&\*;:{}=\-_`~()]/g,"")
                        var correctAnswerWithoutNumbers = correctAnswer.text.replace(/[0-9]/g, '').replace(/[.,\/#!$%\^&\*;:{}=\-_`~()]/g,"")
                        if (userResponseWithoutNumbers.toLowerCase() === correctAnswerWithoutNumbers.toLowerCase()) {
                            flashCard.correct = true
                        }
                    }

                    function nextQuestionOrReturnToMenu(questionIdx) {
                        if (questionIdx === quizLength-1) {
                            navigationStack.push(titlePageComponent)
                        } else {
                            flashDeck.deckIdx++
                        }
                    }
                }
            }
        }
    }

    function selectCardsForQuiz() {
        var shuffledVocab = shuffle(vocab)
        return shuffledVocab.slice(0, quizLength)
    }

    // Fisher-Yates shuffle
    function shuffle(array) {
        var shuffledArray = array.slice()
        for (let i = shuffledArray.length - 1; i > 0; i--) {
            let j = Math.floor(Math.random() * (i + 1)); // random index from 0 to i
            [shuffledArray[i], shuffledArray[j]] = [shuffledArray[j], shuffledArray[i]];
        }
        return shuffledArray
    }

    function parseJson(filePath) {
        var vocabReader = fileUtils.readFile(Qt.resolvedUrl(filePath))
        var vocabJson = JSON.parse(vocabReader)

        for(var i = 0; i < vocabJson.length; i++) {
            var sentenceAndTranslation = vocabJson[i]
            sentenceAndTranslation.correctCantonese = 0
            sentenceAndTranslation.incorrectCantonese = 0
            sentenceAndTranslation.correctEnglish = 0
            sentenceAndTranslation.incorrectEnglish = 0
            vocab.push(sentenceAndTranslation)
        }
    }
}
