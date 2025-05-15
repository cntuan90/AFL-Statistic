import UIKit
import FirebaseFirestore

class HistoryTabViewController: UIViewController {
    
    // MARK: - Properties
    private var completedMatches: [Match] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(HistoryTableViewCell.self, forCellReuseIdentifier: "HistoryCell")
        tableView.rowHeight = 60
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        return tableView
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupFirestoreListener()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        title = "Match History"
        view.backgroundColor = .systemBackground
        
        // Add share button to navigation bar
        let shareButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), 
                                        style: .plain, 
                                        target: self, 
                                        action: #selector(shareButtonTapped))
        navigationItem.rightBarButtonItem = shareButton
        
        // Setup table view
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupFirestoreListener() {
        listener = db.collection("matches")
            .whereField("status", isEqualTo: "Ended")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening to Firestore updates: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                self?.completedMatches = documents.compactMap { document in
                    return Match(document: document)
                }
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
    }
    
    // MARK: - Actions
    @objc private func shareButtonTapped() {
        // Create share text
        var shareText = "Match History:\n\n"
        
        for match in completedMatches {
            let homeGoals = match.home.actions.filter { $0.action == "goal" }.count
            let homeBehinds = match.home.actions.filter { $0.action == "behind" }.count
            let awayGoals = match.away.actions.filter { $0.action == "goal" }.count
            let awayBehinds = match.away.actions.filter { $0.action == "behind" }.count
            
            let homeTotal = homeGoals * 6 + homeBehinds
            let awayTotal = awayGoals * 6 + awayBehinds
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            
            let dateString = match.date ?? "Date not available"
            
            shareText += "\(match.home.name) vs \(match.away.name)\n"
            shareText += "Score: \(homeGoals).\(homeBehinds) (\(homeTotal)) - \(awayGoals).\(awayBehinds) (\(awayTotal))\n"
            shareText += "Date: \(dateString)\n"
            shareText += "Status: \(match.status)\n"
            if let winner = match.winner {
                shareText += "Winner: \(winner)\n"
            }
            shareText += "\n"
        }
        
        // Create activity view controller
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // Present the share sheet
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(activityViewController, animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension HistoryTabViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return completedMatches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryTableViewCell
        let match = completedMatches[indexPath.row]
        
        // Calculate scores
        let homeGoals = match.home.actions.filter { $0.action == "goal" }.count
        let homeBehinds = match.home.actions.filter { $0.action == "behind" }.count
        let awayGoals = match.away.actions.filter { $0.action == "goal" }.count
        let awayBehinds = match.away.actions.filter { $0.action == "behind" }.count
        
        let homeTotal = homeGoals * 6 + homeBehinds
        let awayTotal = awayGoals * 6 + awayBehinds
        
        // Configure cell
        cell.configure(
            teams: "\(match.home.name) vs \(match.away.name)",
            date: match.date ?? "N/A",
            score: "\(homeGoals).\(homeBehinds) (\(homeTotal)) - \(awayGoals).\(awayBehinds) (\(awayTotal))"
        )
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let match = completedMatches[indexPath.row]
        
        // Create and present ImageViewController
        let imageVC = ImageViewController()
        
        // Get the first player's image from either team
        if let firstPlayer = match.home.players.first,
           !firstPlayer.image.isEmpty {
            imageVC.configure(with: firstPlayer.image)
            navigationController?.pushViewController(imageVC, animated: true)
        } else if let firstPlayer = match.away.players.first,
                  !firstPlayer.image.isEmpty {
            imageVC.configure(with: firstPlayer.image)
            navigationController?.pushViewController(imageVC, animated: true)
        } else {
            // Show alert if no player image is available
            let alert = UIAlertController(
                title: "No Image Available",
                message: "No player images are available for this match.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - HistoryTableViewCell
class HistoryTableViewCell: UITableViewCell {
    // MARK: - UI Elements
    private let teamsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        contentView.addSubview(teamsLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(scoreLabel)
        
        NSLayoutConstraint.activate([
            teamsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            teamsLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            teamsLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4),
            
            dateLabel.leadingAnchor.constraint(equalTo: teamsLabel.trailingAnchor, constant: 8),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dateLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.3),
            
            scoreLabel.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 8),
            scoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scoreLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            scoreLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.25)
        ])
    }
    
    // MARK: - Configuration
    func configure(teams: String, date: String, score: String) {
        teamsLabel.text = teams
        dateLabel.text = date
        scoreLabel.text = score
    }
} 
