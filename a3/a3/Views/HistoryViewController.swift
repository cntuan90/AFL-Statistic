import UIKit
import FirebaseFirestore

class HistoryViewController: UIViewController {
    
    // MARK: - Properties
    private var customTabBarController: UITabBarController!
    private let db = Firestore.firestore()
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .right
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
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
        
        // Create navigation controllers for each view controller
        let historyNav = UINavigationController(rootViewController: historyTabVC)
        let timelineNav = UINavigationController(rootViewController: timelineVC)
        let summaryNav = UINavigationController(rootViewController: summaryVC)
        
        // Hide navigation bar for HistoryTabViewController
//        historyNav.setNavigationBarHidden(true, animated: false)
        
        // Configure navigation bars for other view controllers
        [timelineVC, summaryVC].forEach { vc in
            vc.navigationItem.title = ""
            vc.navigationItem.largeTitleDisplayMode = .never
//            vc.navigationItem.hidesBackButton = true
        }
        
        // Add home button to HistoryTabViewController's view
//        let homeButton = UIButton(type: .system)
//        homeButton.setImage(UIImage(systemName: "house.fill"), for: .normal)
//        homeButton.addTarget(self, action: #selector(homeButtonTapped), for: .touchUpInside)
//        homeButton.translatesAutoresizingMaskIntoConstraints = false
//        historyTabVC.view.addSubview(homeButton)
        
        // Set constraints for home button
//        NSLayoutConstraint.activate([
//            homeButton.topAnchor.constraint(equalTo: historyTabVC.view.safeAreaLayoutGuide.topAnchor, constant: 16),
//            homeButton.leadingAnchor.constraint(equalTo: historyTabVC.view.leadingAnchor, constant: 16),
//            homeButton.widthAnchor.constraint(equalToConstant: 44),
//            homeButton.heightAnchor.constraint(equalToConstant: 44)
//        ])
        
        // Configure tab bar items
        historyNav.tabBarItem = UITabBarItem(title: "History", image: UIImage(systemName: "clock"), tag: 0)
        timelineNav.tabBarItem = UITabBarItem(title: "Timeline", image: UIImage(systemName: "list.bullet"), tag: 1)
        summaryNav.tabBarItem = UITabBarItem(title: "Summary", image: UIImage(systemName: "doc.text"), tag: 2)
        
        // Set view controllers
        customTabBarController.viewControllers = [historyNav, timelineNav, summaryNav]
    }
    
//    @objc private func homeButtonTapped() {
//        // Dismiss the entire navigation stack to return to HomeViewController
//        view.window?.rootViewController?.dismiss(animated: true)
//    }
} 
