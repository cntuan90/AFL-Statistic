import UIKit

class HistoryViewController: UIViewController {
    // MARK: - Properties
    private var currentViewController: UIViewController?
    private var selectedTab: Int = 0
    
    // MARK: - UI Elements
    private lazy var tabBar: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.lightGray.cgColor
        return view
    }()
    
    private lazy var summaryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Summary", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(summaryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var timelineButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Timeline", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(timelineButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var historyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("History", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(historyButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupInitialViewController()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .white
        title = "History"
        
        // Add subviews
        view.addSubview(tabBar)
        tabBar.addSubview(summaryButton)
        tabBar.addSubview(timelineButton)
        tabBar.addSubview(historyButton)
        view.addSubview(containerView)
        
        // Setup constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        // Tab bar
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Tab buttons
        summaryButton.translatesAutoresizingMaskIntoConstraints = false
        timelineButton.translatesAutoresizingMaskIntoConstraints = false
        historyButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            summaryButton.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            summaryButton.topAnchor.constraint(equalTo: tabBar.topAnchor),
            summaryButton.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
            summaryButton.widthAnchor.constraint(equalTo: tabBar.widthAnchor, multiplier: 1/3),
            
            timelineButton.leadingAnchor.constraint(equalTo: summaryButton.trailingAnchor),
            timelineButton.topAnchor.constraint(equalTo: tabBar.topAnchor),
            timelineButton.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
            timelineButton.widthAnchor.constraint(equalTo: tabBar.widthAnchor, multiplier: 1/3),
            
            historyButton.leadingAnchor.constraint(equalTo: timelineButton.trailingAnchor),
            historyButton.topAnchor.constraint(equalTo: tabBar.topAnchor),
            historyButton.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
            historyButton.widthAnchor.constraint(equalTo: tabBar.widthAnchor, multiplier: 1/3)
        ])
        
        // Container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupInitialViewController() {
        let summaryVC = SummaryViewController()
        addChild(summaryVC)
        containerView.addSubview(summaryVC.view)
        summaryVC.view.frame = containerView.bounds
        summaryVC.didMove(toParent: self)
        currentViewController = summaryVC
        updateTabSelection(0)
    }
    
    // MARK: - Action Methods
    @objc private func summaryButtonTapped() {
        switchToViewController(SummaryViewController(), tabIndex: 0)
    }
    
    @objc private func timelineButtonTapped() {
        switchToViewController(TimelineViewController(), tabIndex: 1)
    }
    
    @objc private func historyButtonTapped() {
        switchToViewController(HistoryTabViewController(), tabIndex: 2)
    }
    
    // MARK: - Helper Methods
    private func switchToViewController(_ viewController: UIViewController, tabIndex: Int) {
        // Remove current view controller
        currentViewController?.willMove(toParent: nil)
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()
        
        // Add new view controller
        addChild(viewController)
        containerView.addSubview(viewController.view)
        viewController.view.frame = containerView.bounds
        viewController.didMove(toParent: self)
        currentViewController = viewController
        
        // Update tab selection
        updateTabSelection(tabIndex)
    }
    
    private func updateTabSelection(_ tabIndex: Int) {
        selectedTab = tabIndex
        
        // Reset all buttons
        [summaryButton, timelineButton, historyButton].forEach { button in
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
        }
        
        // Highlight selected button
        let selectedButton: UIButton
        switch tabIndex {
        case 0:
            selectedButton = summaryButton
        case 1:
            selectedButton = timelineButton
        case 2:
            selectedButton = historyButton
        default:
            return
        }
        
        selectedButton.backgroundColor = UIColor(red: 0.2, green: 0.51, blue: 0.74, alpha: 1.0)
        selectedButton.setTitleColor(.white, for: .normal)
    }
} 