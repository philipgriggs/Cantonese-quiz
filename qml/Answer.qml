import QtQuick 2.0
import Felgo 3.0

Item {
    id: answer
    property bool submittedAnswer: false
    property bool correct: false
    property bool answerable
    property string correctAnswer
    property var checkAnswerCallback
    height: correctAnswerAppText.height + userResponseSubmitted.height
    width: answerable && !submittedAnswer ? userResponse.paintedWidth > placeHolderText.paintedWidth ? userResponse.paintedWidth : placeHolderText.paintedWidth : correctAnswerAppText.paintedWidth
    Column {
        spacing: 20
        // a text box containing the placeholder text "answer" - don't render it, instead this is just used to set the placeholder text width
        AppTextEdit {
            id: placeHolderText
            anchors.horizontalCenter: parent.horizontalCenter
            text: "answer"
            visible: false
            horizontalAlignment: TextEdit.AlignHCenter
        }
        // where the user may type their response
        AppTextEdit {
            id: userResponse
            anchors.horizontalCenter: parent.horizontalCenter
            visible: answerable && !answer.submittedAnswer
            width: answer.width //text === "" ? answer.width : userResponse.paintedWidth
            placeholderText: focus ? "" : placeHolderText.text
            horizontalAlignment: TextEdit.AlignHCenter
            Keys.onReturnPressed: {
                focus = false
                answer.checkAnswer()
            }
        }
        // once the user has submitted their response, then hide the text edit box and show their answer in green or red (correct / incorrect)
        AppText {
            id: userResponseSubmitted
            anchors.horizontalCenter: parent.horizontalCenter
            visible: answer.submittedAnswer
            text: answer.correct ? correctAnswerAppText.text : userResponse.text
            color: answer.correct ? "green" : "red"
            horizontalAlignment: TextEdit.AlignHCenter
        }
        // show the correct answer after the user submitted
        AppText {
            id: correctAnswerAppText
            anchors.horizontalCenter: parent.horizontalCenter
            text: answer.correctAnswer
            visible: !answer.answerable || (answer.submittedAnswer && !answer.correct)
            horizontalAlignment: TextEdit.AlignHCenter
        }
    }
    function checkAnswer() {
        answer.submittedAnswer = true
        // remove any numbers, punctuation, leading, trailing or double spaces
        var userResponseWithoutNumbers = userResponse.text.replace(/[0-9]/g,'').replace(/[.,\/#!$%\^&\*;:{}=?\-_`~()]/g,'').replace(/^\s+/g,"").replace(/\s+$/g,'').replace(/\s+/g,' ')
        var correctAnswerWithoutNumbers = answer.correctAnswer.replace(/[0-9]/g,'').replace(/[.,\/#!$%\^&\*;:{}=?\-_`~()]/g,'').replace(/^\s+/g,"").replace(/\s+$/g,'')
        if (userResponseWithoutNumbers.toLowerCase() === correctAnswerWithoutNumbers.toLowerCase()) {
            answer.correct = true
        }
        answer.checkAnswerCallback(answer.correct)
    }
}
