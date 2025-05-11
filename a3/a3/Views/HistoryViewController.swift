import UIKit
import FirebaseFirestore

class HistoryViewController: UIViewController {
    
    // MARK: - Properties
    private var customTabBarController: UITabBarController!
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarController()
    }
    
    // MARK: - Setup Methods
    private func setupTabBarController() {
        // Create tab bar controller
        customTabBarController = UITabBarController()
        addChild(customTabBarController)
        view.addSubview(customTabBarController.view)
        customTabBarController.view.frame = view.bounds
        customTabBarController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        customTabBarController.didMove(toParent: self)
        
        // Create view controllers for each tab
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let historyTabVC = storyboard.instantiateViewController(withIdentifier: "HistoryTabViewController") as! HistoryTabViewController
        let timelineVC = storyboard.instantiateViewController(withIdentifier: "TimelineViewController") as! TimelineViewController
        let summaryVC = storyboard.instantiateViewController(withIdentifier: "SummaryViewController") as! SummaryViewController
        
        // Configure tab bar items
        historyTabVC.tabBarItem = UITabBarItem(title: "History", image: UIImage(systemName: "clock"), tag: 0)
        timelineVC.tabBarItem = UITabBarItem(title: "Timeline", image: UIImage(systemName: "list.bullet"), tag: 1)
        summaryVC.tabBarItem = UITabBarItem(title: "Summary", image: UIImage(systemName: "doc.text"), tag: 2)
        
        // Set view controllers
        customTabBarController.viewControllers = [historyTabVC, timelineVC, summaryVC]
    }
} 
