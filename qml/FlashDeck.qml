import QtQuick 2.0
import Felgo 3.0

Page {
    id: flashDeck
    property int deckIdx: 0
    property var questions: []
    title: "Quiz"

    Repeater {
        id: questionRepeater
        model: flashDeck.questions
        // one column per question in the quiz, only the current question is visible
        Column {
            id: question
            visible: index === flashDeck.deckIdx
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 300
            spacing: 20
            property bool submittedAllAnswers: false
            property var questionAndAnswer: modelData

            // the question text
            AppText {
                id: prompt
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.question
            }

            // the answer text, which may be split up into multiple parts of the sentence
            Row {
                id: answers
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                Repeater {
                    id: answerSubclauseRepeater
                    model: question.questionAndAnswer.answers // answers is each subclause
                    Answer {
                        answerable: index === question.questionAndAnswer.blankIndex
                        correctAnswer: modelData
                        checkAnswerCallback: function(correct) {
                            vocabStorage.incrementStatsAndSave(question.questionAndAnswer, correct)
                            question.submittedAllAnswers = answers.allSubmitted()
                        }
                    }
                }
                function allSubmitted() {
                    for (var i = 0; i < question.questionAndAnswer.answers.length; i++) {
                        var answerSubclause = answerSubclauseRepeater.itemAt(i)
                        if (answerSubclause.answerable && !answerSubclause.submittedAnswer) {
                            return false
                        }
                    }
                    return true
                }
            }
            AppText {
                text: 'correct cantonese: ' + vocabStorage.vocab[question.questionAndAnswer.index].correctCantonese.join()
            }
            AppText {
                text: 'correct english: ' + vocabStorage.vocab[question.questionAndAnswer.index].correctEnglish.join()
            }

            // button to move onto the next question or to finish the quiz
            AppButton {
                id: nextCardButton
                anchors.horizontalCenter: parent.horizontalCenter
                visible: question.submittedAllAnswers
                text: index === flashDeck.questions.length - 1 ? "finish" : "next"
                onClicked: question.nextQuestionOrReturnToMenu(index)
            }

            function nextQuestionOrReturnToMenu(questionIdx) {
                if (questionIdx === flashDeck.questions.length-1) {
                    navigationStack.push(titlePageComponent)
                } else {
                    flashDeck.deckIdx++
                }
            }
        }
    }
}
