import Foundation

class Question {
    var question: String?
    var answer: Bool?
    var passage: String?
    
    init(question: String, answer: Bool, passage: String) {
        self.question = question
        self.answer = answer
        self.passage = passage
    }
}
