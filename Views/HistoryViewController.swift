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
        
        // Add share button
        let shareButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareButtonTapped))
        navigationItem.rightBarButtonItem = shareButton
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
        
        // Configure tab bar items
        historyNav.tabBarItem = UITabBarItem(title: "History", image: UIImage(systemName: "clock"), tag: 0)
        timelineNav.tabBarItem = UITabBarItem(title: "Timeline", image: UIImage(systemName: "list.bullet"), tag: 1)
        summaryNav.tabBarItem = UITabBarItem(title: "Summary", image: UIImage(systemName: "doc.text"), tag: 2)
        
        // Set view controllers
        customTabBarController.viewControllers = [historyNav, timelineNav, summaryNav]
    }
    
    // MARK: - Share Methods
    @objc private func shareButtonTapped() {
        // Get the current tab's view controller
        guard let currentNav = customTabBarController.selectedViewController as? UINavigationController,
              let currentVC = currentNav.topViewController else { return }
        
        var shareText = "Match History Summary\n\n"
        
        if let historyVC = currentVC as? HistoryTabViewController {
            // Share all completed matches
            for match in historyVC.completedMatches {
                shareText += """
                Match: \(match.home.name) vs \(match.away.name)
                Date: \(match.date ?? "N/A")
                Score: \(match.homeScore) - \(match.awayScore)
                
                """
            }
        } else if let timelineVC = currentVC as? TimelineViewController {
            // Share all matches with timeline details
            for match in timelineVC.matches {
                shareText += """
                Match Timeline: \(match.home.name) vs \(match.away.name)
                Date: \(match.date ?? "N/A")
                Score: \(match.homeScore) - \(match.awayScore)
                
                Home Team (\(match.home.name)) Records:
                """
                
                // Add home team records
                for action in match.home.actions.sorted(by: { $0.time < $1.time }) {
                    shareText += "\n\(action.time) - \(action.playerName): \(action.action)"
                }
                
                shareText += "\n\nAway Team (\(match.away.name)) Records:"
                
                // Add away team records
                for action in match.away.actions.sorted(by: { $0.time < $1.time }) {
                    shareText += "\n\(action.time) - \(action.playerName): \(action.action)"
                }
                
                shareText += "\n\n"
            }
        } else if let summaryVC = currentVC as? SummaryViewController {
            // Share all matches with summary details
            for match in summaryVC.matches {
                shareText += """
                Match Summary: \(match.home.name) vs \(match.away.name)
                Date: \(match.date ?? "N/A")
                Score: \(match.homeScore) - \(match.awayScore)
                
                Home Team (\(match.home.name)) Records:
                """
                
                // Add home team records
                for action in match.home.actions.sorted(by: { $0.time < $1.time }) {
                    shareText += "\n\(action.time) - \(action.playerName): \(action.action)"
                }
                
                shareText += "\n\nAway Team (\(match.away.name)) Records:"
                
                // Add away team records
                for action in match.away.actions.sorted(by: { $0.time < $1.time }) {
                    shareText += "\n\(action.time) - \(action.playerName): \(action.action)"
                }
                
                shareText += "\n\n"
            }
        }
        
        // Create activity view controller
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        // Present the share sheet
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(activityVC, animated: true)
    }
} 
