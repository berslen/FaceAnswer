import Foundation
import CoreData

@objc(QuizResults)
public class QuizResults: NSManagedObject {
    
    class func createInManagedObjectContext(_ context: NSManagedObjectContext, username: String, score: NSNumber, date:NSDate){
        let questionObject = NSEntityDescription.insertNewObject(forEntityName: "QuizResults", into: context) as! QuizResults
        questionObject.score = score
        questionObject.username = username
        questionObject.date = date
    }
}
