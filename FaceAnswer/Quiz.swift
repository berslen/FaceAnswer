//
//  Quiz.swift
//  FaceAnswer
//
//  Created by Berslen AKKAYA on 27.05.2022.
//

import Foundation

struct Quiz {
    
    var allQuestions = [Question]()
    var quiz = [Question]()
    
    var questionNumber = 0
    var score = 0
    
    mutating func checkAnswer(userAnswer: Bool) -> Bool {
        if userAnswer == quiz[questionNumber].answer {
            score += 1
            return true
        }
        else{
            return false
        }
    }
    
    mutating func resetQuiz(){
        self.questionNumber = 0
        self.score = 0
    }
    
    func getQuestionText() -> String {
        return quiz[questionNumber].question!
    }
    
    func getProgress() -> Float {
        let progress = Float(questionNumber)/Float(quiz.count)
        return progress
    }
    
    mutating func nextQuestion() {
        if questionNumber + 1 < quiz.count {
            questionNumber += 1
        }else{
            questionNumber = 0
            score = 0
        }
    }
    
    func getScore () -> Int {
        return score
    }
    
    mutating func readJson(){
        if let path = Bundle.main.path(forResource: "questions", ofType: "json") {
            if let jsonToParse = NSData(contentsOfFile: path) {
                
                guard let json = try? JSON(data: jsonToParse as Data) else {
                    print("Error with JSON")
                    return
                }
                
                for index in 0..<json.count {
                    let question = Question(question: json[index]["question"].string!, answer: json[index]["answer"].bool!, passage: json[index]["passage"].string!)
                    allQuestions.insert(question, at:index)
                }
            }
            else {
                print("NSdata error")
            }
        }
        else {
            print("NSURL error")
        }
    }
}
