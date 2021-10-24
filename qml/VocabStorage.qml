import QtQuick 2.0
import Felgo 3.0

Item {
    id: vocab_storage

    // all the vocab in the file
    property var vocab: []
    property int quizLength
    property int learnedWords
    property int requiredCorrect: 3

    // persistent storage
    Storage {
        id: persistentStorage

        Component.onCompleted: {
            var vocabPersisted = persistentStorage.getValue("vocab")
            if (vocabPersisted) {
                vocab = vocabPersisted
            }
        }
        function save() {
            persistentStorage.setValue("vocab", vocab)
        }
    }

    // shuffle the questions and choose the first n to use in the quiz
    function selectCardsForQuiz() {
        var shuffledVocab = shuffleVocab()
        var questionsAndAnswers = []
        for (let i = 0; i < quizLength; i++) {
            // the answer may be either english or cantonese
            var questionAndAnswers = {
                "question": shuffledVocab[i].Cantonese.join(''),
                "answers": shuffledVocab[i].English,
                "index": shuffledVocab[i].index,
                "isEnglish": true
            }
            // every other question is answered in cantonese, except if the user exceeded the required correct answers in Cantonese
            // or the question is in cantonese if the user exceeded the required correct answers in English
            if (i%2 === 0 && !checkRequiredCorrect(vocab[shuffledVocab[i].index].correctCantonese) || checkRequiredCorrect(vocab[shuffledVocab[i].index].correctEnglish)) {
                questionAndAnswers.question = shuffledVocab[i].English.join('')
                questionAndAnswers.answers = shuffledVocab[i].Cantonese
                questionAndAnswers.isEnglish = false
            }
            questionAndAnswers = chooseAnswer(questionAndAnswers)
            questionsAndAnswers.push(questionAndAnswers)
        }
        return questionsAndAnswers
    }

    // choose which of the sub part of the sentence should be blank
    function chooseAnswer(questionAndAnswers) {
        var validAnswer = false
        while (true) {
            questionAndAnswers.blankIndex = Math.floor(Math.random()*questionAndAnswers.answers.length)
            var correctAnswerCount = vocab[questionAndAnswers.index].correctCantonese
            if (questionAndAnswers.isEnglish) {
                correctAnswerCount = vocab[questionAndAnswers.index].correctEnglish
            }
            if (correctAnswerCount[questionAndAnswers.blankIndex] < requiredCorrect) {
                break
            }
        }
        return questionAndAnswers
    }

    // Fisher-Yates shuffle
    function shuffleVocab() {
        var chosenWords = []
        for (let vocabIdx = 0; vocabIdx < vocab.length && chosenWords.length < learnedWords; vocabIdx++) {
            if (!checkRequiredCorrect(vocab[vocabIdx].correctCantonese)) {
                chosenWords.push(vocab[vocabIdx])
                continue
            }
            if (!checkRequiredCorrect(vocab[vocabIdx].correctEnglish)) {
                chosenWords.push(vocab[vocabIdx])
            }
        }

        for (let i = chosenWords.length - 1; i > 0; i--) {
            let j = Math.floor(Math.random() * (i + 1)); // random index from 0 to i
            [chosenWords[i], chosenWords[j]] = [chosenWords[j], chosenWords[i]];
        }
        return chosenWords
    }

    // return true if all of the split answers exceed the required correct
    function checkRequiredCorrect(correctArray) {
        for (let answerIdx = 0; answerIdx < correctArray.length; answerIdx++) {
            if (correctArray[answerIdx] < requiredCorrect) {
                return false
            }
        }
        return true
    }

    // read the json file and put into a local object
    function parseJson(filePath) {
        var vocabReader = fileUtils.readFile(Qt.resolvedUrl(filePath))
        var vocabJson = JSON.parse(vocabReader)

        for(var i = 0; i < vocabJson.length; i++) {
            var splitCantonese = vocabJson[i].Cantonese.split('\b')
            var splitEnglish = vocabJson[i].English.split('\b')
            // object containing each sub answer (split by charset `\b`) and counter of how many of each were correct
            vocab.push({
                           "Cantonese": splitCantonese,
                           "English": splitEnglish,
                           "correctCantonese": new Array(splitCantonese.length).fill(0),
                           "correctEnglish": new Array(splitEnglish.length).fill(0),
                           "index": i,
                       })
        }
    }

    function incrementStatsAndSave(questionAndAnswer, correct) {
        incrementStats(questionAndAnswer, correct)
        persistentStorage.save()
    }

    function incrementStats(questionAndAnswer, correct) {
        var data = vocab[questionAndAnswer.index]
        if (questionAndAnswer.isEnglish && correct) {
            data.correctEnglish[questionAndAnswer.blankIndex]++
            return
        }
        if (questionAndAnswer.isEnglish && !correct && data.correctEnglish > 0) {
            data.correctEnglish[questionAndAnswer.blankIndex]--
            return
        }
        if (!questionAndAnswer.isEnglish && correct) {
            data.correctCantonese[questionAndAnswer.blankIndex]++
            return
        }
        if (!questionAndAnswer.isEnglish && !correct && data.correctCantonese > 0) {
            data.correctCantonese[questionAndAnswer.blankIndex]--
            return
        }
    }
}
