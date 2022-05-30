import UIKit
import CoreData

class ScoreboardVC: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    @IBOutlet weak var tableView:UITableView!
    var quizResults = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        fetchData()
    }
    
     func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quizResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath) as UITableViewCell
        
        // Configure the cell...
        let quizResult = quizResults[indexPath.row]
        cell.textLabel?.text = (quizResult.value(forKey: "username") as? String)?.uppercased()
        cell.detailTextLabel?.text = (quizResult.value(forKey: "score") as? NSNumber)?.stringValue
        
        if(
            quizResults.max(by: { a, b in
                ((a.value(forKey: "date") as? Date)!) < (b.value(forKey: "date") as? Date)!}) == quizResult){
            cell.backgroundColor = UIColor.lightGray
        }
        
        return cell
    }
    
    func fetchData() {
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QuizResults")
        
        do {
            let results = try context.fetch(fetchRequest)
            quizResults = (results as! [NSManagedObject]).sorted(by: { a, b in
                (a.value(forKey: "score") as? Int)! > (b.value(forKey: "score") as? Int)!})
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
}
