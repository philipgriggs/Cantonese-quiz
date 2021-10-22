import QtQuick 2.0
import Felgo 3.0

Item {
    id: vocab_storage

    // all the vocab in the file
    property var vocab: []

    // shuffle the questions and choose the first n to use in the quiz
    function selectCardsForQuiz() {
        var shuffledVocab = shuffle(vocab)
        var splitQuestionAndAnsers = []
        for (var i = 0; i < quizLength; i++) {
            // the answer may be either english or cantonese
            var question = shuffledVocab[i].Cantonese
            var answer = shuffledVocab[i].English
            if (i%2 === 0) {
                question = shuffledVocab[i].English
                answer = shuffledVocab[i].Cantonese
            }
            var questionAndAnswer = splitAnswers(question, answer)
            splitQuestionAndAnsers.push(questionAndAnswer)
        }
        return splitQuestionAndAnsers
    }

    // split up the anwers by the special charset `\b`
    function splitAnswers(question, answer) {
        var splitAnswers = answer.split('\b')
        var blankAnswerIdx = Math.floor(Math.random()*splitAnswers.length)
        var questionAndAnswer = {
            "question": question,
            "answers": []
        }
        for (var i = 0; i < splitAnswers.length; i++) {
            questionAndAnswer.answers.push({
                                               "answer": splitAnswers[i],
                                               "isBlank": i === blankAnswerIdx
                                           })
        }
        return questionAndAnswer
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
