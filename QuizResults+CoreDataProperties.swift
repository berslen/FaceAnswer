import Foundation
import CoreData

extension QuizResults {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuizResults> {
        return NSFetchRequest<QuizResults>(entityName: "QuizResults")
    }

    @NSManaged public var username: String?
    @NSManaged public var score: NSNumber?
    @NSManaged public var date: NSDate?
}
