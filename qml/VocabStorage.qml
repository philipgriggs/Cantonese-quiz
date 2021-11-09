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
            parseJson("../assets/vocab.json")
            var vocabPersisted = persistentStorage.getValue("vocab")
            if (vocabPersisted) {
                loadState(vocabPersisted)
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
            // one of the questions might be a revision question of a previously learned word, so handle this special case
            var got = getReminderQuestion(shuffledVocab[i], function(reminderQuestion) {
                questionsAndAnswers.push(reminderQuestion)
            })
            if (got) {
                continue
            }

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

    // one of the questions might be a revision question of a previously learned word, so handle this special case
    function getReminderQuestion(question, callback) {
        if (!question.reminderQuestion) {
            return false
        }

        if (question.isEnglish) {
            callback({
                         "question": question.Cantonese.join(''),
                         "answers": question.English,
                         "index": question.index,
                         "isEnglish": true,
                         "blankIndex": question.answerIndex
                     })
        } else {
            callback({
                         "question": question.English.join(''),
                         "answers": question.Cantonese,
                         "index": question.index,
                         "isEnglish": false,
                         "blankIndex": question.answerIndex
                     })
        }
        return true
    }

    // choose which of the sub part of the sentence should be blank
    function chooseAnswer(questionAndAnswers) {
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
        var leastCorrect = leastCorrectQuestion()
        if (leastCorrect) {
            chosenWords[chosenWords.length-1] = leastCorrect
        }

        for (let i = chosenWords.length - 1; i > 0; i--) {
            let j = Math.floor(Math.random() * (i + 1)); // random index from 0 to i
            [chosenWords[i], chosenWords[j]] = [chosenWords[j], chosenWords[i]];
        }
        return chosenWords
    }

    // return the question that has passed the correct requirement by the smallest amount
    function leastCorrectQuestion() {
        var leastCorrect = {
            "vocabIndex": -1,
            "answerIndex": -1,
            "count": 1e9,
            "isEnglish": false
        }

        forEach(vocab, function(vocabIdx, voc) {
            var tentativeLeastCorrect = {
                "vocabIndex": -1,
                "count": 1e9
            }

            // iterate the score of the cantonese answers
            var allCorrect = true
            forEach(voc.correctCantonese, function(answerIdx, correctCount) {
                // only consider answers where all subclauses are correct
                allCorrect = allCorrect && correctCount >= requiredCorrect

                // keep this question if it's correct, and less that the current minimum, and the minimum in this iteration
                if (correctCount >= requiredCorrect && correctCount < leastCorrect.count && correctCount < tentativeLeastCorrect.count) {
                    tentativeLeastCorrect = {
                        "vocabIndex": vocabIdx,
                        "answerIndex": answerIdx,
                        "count": correctCount,
                        "isEnglish": false
                    }
                }
            })
            // we found a possible minimum candidate
            if (allCorrect && tentativeLeastCorrect.vocabIndex !== -1) {
                leastCorrect = tentativeLeastCorrect
            }
            // reset variables
            allCorrect = false
            tentativeLeastCorrect = {
                "vocabIndex": -1,
                "count": 1e9
            }

            // iterate the score of the english answers
            forEach(voc.correctEnglish, function(answerIdx, correctCount) {
                // only consider answers where all subclauses are correct
                allCorrect = allCorrect && correctCount >= requiredCorrect

                // keep this question if it's correct, and less that the current minimum, and the minimum in this iteration
                if (correctCount >= requiredCorrect && correctCount < leastCorrect.count && correctCount < tentativeLeastCorrect.count) {
                    tentativeLeastCorrect = {
                        "vocabIndex": vocabIdx,
                        "anserIndex": answerIdx,
                        "count": correctCount,
                        "isEnglish": true
                    }
                }
            })
            // we found a possible minimum candidate
            if (allCorrect && tentativeLeastCorrect.vocabIndex !== -1) {
                leastCorrect = tentativeLeastCorrect
            }
        })

        if (leastCorrect.vocabIndex === -1) {
            return null
        }
        var v = vocab[leastCorrect.vocabIndex]
        v.reminderQuestion = true
        v.isEnglish = leastCorrect.isEnglish
        v.answerIndex = leastCorrect.answerIndex
        return v
    }

    function forEach(array, callback) {
        for (let idx = 0; idx < array.length; idx++) {
            callback(idx, array[idx])
        }
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

    function loadState(vocabPersisted) {
        forEach(vocabPersisted, function(idx, vocabPersist) {
            if (vocab[idx].Cantonese.length === vocabPersist.Cantonese.length) {
                vocab[idx].correctCantonese = vocabPersist.correctCantonese
            }
            if (vocab[idx].English.length === vocabPersist.English.length) {
                vocab[idx].correctEnglish = vocabPersist.correctEnglish
            }
        })
    }
}
