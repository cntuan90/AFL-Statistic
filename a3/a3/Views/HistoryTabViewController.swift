import UIKit
import FirebaseFirestore

class HistoryTabViewController: UIViewController {
    
    // MARK: - Properties
    private var completedMatches: [Match] = []
    private var selectedMatch: Match?
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
        
        // Add share button if not already set
        if navigationItem.rightBarButtonItem == nil {
            let shareButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareButtonTapped))
            navigationItem.rightBarButtonItem = shareButton
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        title = "Match History"
        view.backgroundColor = .systemBackground
        
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
    @objc func shareButtonTapped() {
        guard let match = selectedMatch else {
            // Show alert if no match is selected
            let alert = UIAlertController(
                title: "No Match Selected",
                message: "Please select a match to share.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Create share text
        let shareText = """
        Match Summary: \(match.home.name) vs \(match.away.name)
        Date: \(match.date)
        Score: \(match.homeScore) - \(match.awayScore) 
        """
        
        // Create activity view controller
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        // Present the share sheet
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(activityVC, animated: true)
    }
    
    // MARK: - Helper Methods
    private func calculateMatchScore(_ match: Match) -> (homeScore: String, awayScore: String, winner: String) {
        // Calculate goals and behinds for each quarter
        let homeScoreQ1Goals = match.home.actions.filter { $0.action == "goal" && $0.actionQuarter == 1 }.count
        let homeScoreQ1Behinds = match.home.actions.filter { $0.action == "behind" && $0.actionQuarter == 1 }.count
        let awayScoreQ1Goals = match.away.actions.filter { $0.action == "goal" && $0.actionQuarter == 1 }.count
        let awayScoreQ1Behinds = match.away.actions.filter { $0.action == "behind" && $0.actionQuarter == 1 }.count
        
        let homeScoreQ2Goals = match.home.actions.filter { $0.action == "goal" && $0.actionQuarter == 2 }.count + homeScoreQ1Goals
        let homeScoreQ2Behinds = match.home.actions.filter { $0.action == "behind" && $0.actionQuarter == 2 }.count + homeScoreQ1Behinds
        let awayScoreQ2Goals = match.away.actions.filter { $0.action == "goal" && $0.actionQuarter == 2 }.count + awayScoreQ1Goals
        let awayScoreQ2Behinds = match.away.actions.filter { $0.action == "behind" && $0.actionQuarter == 2 }.count + awayScoreQ1Behinds
        
        let homeScoreQ3Goals = match.home.actions.filter { $0.action == "goal" && $0.actionQuarter == 3 }.count + homeScoreQ2Goals
        let homeScoreQ3Behinds = match.home.actions.filter { $0.action == "behind" && $0.actionQuarter == 3 }.count + homeScoreQ2Behinds
        let awayScoreQ3Goals = match.away.actions.filter { $0.action == "goal" && $0.actionQuarter == 3 }.count + awayScoreQ2Goals
        let awayScoreQ3Behinds = match.away.actions.filter { $0.action == "behind" && $0.actionQuarter == 3 }.count + awayScoreQ2Behinds
        
        let homeScoreFinalGoals = match.home.actions.filter { $0.action == "goal" && $0.actionQuarter == 4 }.count + homeScoreQ3Goals
        let homeScoreFinalBehinds = match.home.actions.filter { $0.action == "behind" && $0.actionQuarter == 4 }.count + homeScoreQ3Behinds
        let homeScoreFinalTotal = homeScoreFinalGoals * 6 + homeScoreFinalBehinds
        
        let awayScoreFinalGoals = match.away.actions.filter { $0.action == "goal" && $0.actionQuarter == 4 }.count + awayScoreQ3Goals
        let awayScoreFinalBehinds = match.away.actions.filter { $0.action == "behind" && $0.actionQuarter == 4 }.count + awayScoreQ3Behinds
        let awayScoreFinalTotal = awayScoreFinalGoals * 6 + awayScoreFinalBehinds
        
        // Format scores
        let homeScore = String(format: "%d . %d (%d)", homeScoreFinalGoals, homeScoreFinalBehinds, homeScoreFinalTotal)
        let awayScore = String(format: "%d . %d (%d)", awayScoreFinalGoals, awayScoreFinalBehinds, awayScoreFinalTotal)
        
        // Determine winner
        let winner: String
        if homeScoreFinalTotal > awayScoreFinalTotal {
            winner = "Home"
        } else if homeScoreFinalTotal < awayScoreFinalTotal {
            winner = "Away"
        } else {
            winner = "Draw"
        }
        
        return (homeScore, awayScore, winner)
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
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//        selectedMatch = completedMatches[indexPath.row]
//        
//        // Create and present ImageViewController
//        let imageVC = ImageViewController()
//        
//        // Get the first player's image from either team
//        if let firstPlayer = selectedMatch?.home.players.first,
//           !firstPlayer.image.isEmpty {
//            imageVC.configure(with: firstPlayer.image)
//            navigationController?.pushViewController(imageVC, animated: true)
//        } else if let firstPlayer = selectedMatch?.away.players.first,
//                  !firstPlayer.image.isEmpty {
//            imageVC.configure(with: firstPlayer.image)
//            navigationController?.pushViewController(imageVC, animated: true)
//        } else {
//            // Show alert if no player image is available
//            let alert = UIAlertController(
//                title: "No Image Available",
//                message: "No player images are available for this match.",
//                preferredStyle: .alert
//            )
//            alert.addAction(UIAlertAction(title: "OK", style: .default))
//            present(alert, animated: true)
//        }
//    }
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
