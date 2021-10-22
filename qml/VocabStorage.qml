import QtQuick 2.0
import Felgo 3.0

Item {
    id: vocab_storage

    // all the vocab in the file
    property var vocab: []
    property int quizLength
    property int learnedWords
    property int requiredCorrect: 1

    // shuffle the questions and choose the first n to use in the quiz
    function selectCardsForQuiz() {
        var shuffledVocab = shuffleVocab()
        var splitQuestionAndAnswers = []
        for (var i = 0; i < quizLength; i++) {
            // the answer may be either english or cantonese
            var questionAndAnswer = {
                "question": shuffledVocab[i].Cantonese,
                "answer": shuffledVocab[i].English,
                "index": shuffledVocab[i].index,
                "isEnglish": true
            }
            if (i%2 === 0) {
                questionAndAnswer.question = shuffledVocab[i].English
                questionAndAnswer.answer = shuffledVocab[i].Cantonese
                questionAndAnswer.isEnglish = false
            }
            var splitQuestionAndAnswer = splitAnswers(questionAndAnswer)
            splitQuestionAndAnswers.push(splitQuestionAndAnswer)
        }
        return splitQuestionAndAnswers
    }

    // split up the anwers by the special charset `\b`
    function splitAnswers(questionAndAnswer) {
        var splitAnswers = questionAndAnswer.answer.split('\b')
        var blankAnswerIdx = Math.floor(Math.random()*splitAnswers.length)
        var splitQuestionAndAnswer = {
            "question": questionAndAnswer.question,
            "answers": [],
            "index": questionAndAnswer.index,
            "isEnglish": questionAndAnswer.isEnglish
        }
        for (var i = 0; i < splitAnswers.length; i++) {
            splitQuestionAndAnswer.answers.push({
                                                    "answer": splitAnswers[i],
                                                    "isBlank": i === blankAnswerIdx
                                                })
        }
        return splitQuestionAndAnswer
    }

    // Fisher-Yates shuffle
    function shuffleVocab() {
        var chosenWords = []
        for (var i = 0; i < vocab.length && chosenWords.length < learnedWords; i++) {
            if (vocab[i].correctCantonese < requiredCorrect || vocab[i].correctEnglish < requiredCorrect) {
                chosenWords.push(vocab[i])
            }
        }

        for (let i = chosenWords.length - 1; i > 0; i--) {
            let j = Math.floor(Math.random() * (i + 1)); // random index from 0 to i
            [chosenWords[i], chosenWords[j]] = [chosenWords[j], chosenWords[i]];
        }
        return chosenWords
    }

    function parseJson(filePath) {
        var vocabReader = fileUtils.readFile(Qt.resolvedUrl(filePath))
        var vocabJson = JSON.parse(vocabReader)

        for(var i = 0; i < vocabJson.length; i++) {
            var sentenceAndTranslation = vocabJson[i]
            sentenceAndTranslation.correctCantonese = 0
            sentenceAndTranslation.correctEnglish = 0
            sentenceAndTranslation.index = i
            vocab.push(sentenceAndTranslation)
        }
    }

    function incrementStats(questionAndAnswer, correct) {
        var data = vocab[questionAndAnswer.index]
        if (questionAndAnswer.isEnglish && correct) {
            data.correctEnglish++
            return
        }
        if (questionAndAnswer.isEnglish && !correct && data.correctEnglish > 0) {
            data.correctEnglish--
            return
        }
        if (!questionAndAnswer.isEnglish && correct) {
            data.correctCantonese++
            return
        }
        if (!questionAndAnswer.isEnglish && !correct && data.correctCantonese > 0) {
            data.correctCantonese--
            return
        }
    }
}
