import UIKit
import FirebaseFirestore

class HistoryTabViewController: UIViewController {
    
    // MARK: - Properties
    var completedMatches: [Match] = []
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
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
        
        // Determine winner
        let isHomeWinner = homeTotal > awayTotal
        
        // Configure cell
        cell.configure(
            teams: "\(match.home.name) vs \(match.away.name)",
            date: match.date ?? "N/A",
            score: "\(homeGoals).\(homeBehinds) (\(homeTotal)) - \(awayGoals).\(awayBehinds) (\(awayTotal))",
            isHomeWinner: isHomeWinner
        )
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedMatch = completedMatches[indexPath.row]
        
        // Create and present StatsComparisonViewController programmatically
        let statsVC = StatsComparisonViewController()
        statsVC.match = selectedMatch
        navigationController?.pushViewController(statsVC, animated: true)
    }
}

// MARK: - HistoryTableViewCell
class HistoryTableViewCell: UITableViewCell {
    // MARK: - UI Elements
    private let teamsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 2
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
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontSizeToFitWidth = true
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
            teamsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            teamsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            teamsLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.3),
            
            dateLabel.leadingAnchor.constraint(equalTo: teamsLabel.trailingAnchor, constant: 8),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dateLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.3),
            
            scoreLabel.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 8),
            scoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scoreLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            scoreLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.35)
        ])
    }
    
    // MARK: - Configuration
    func configure(teams: String, date: String, score: String, isHomeWinner: Bool) {
        teamsLabel.text = teams
        dateLabel.text = date
        
        // Create attributed string for score
        let attributedScore = NSMutableAttributedString(string: score)
        
        // Find the score parts
        let components = score.components(separatedBy: " - ")
        if components.count == 2 {
            let homeScore = components[0]
            let awayScore = components[1]
            
            // Highlight the winner's score
            if isHomeWinner {
                let homeRange = (score as NSString).range(of: homeScore)
                attributedScore.addAttribute(.foregroundColor, value: UIColor.systemGreen, range: homeRange)
            } else {
                let awayRange = (score as NSString).range(of: awayScore)
                attributedScore.addAttribute(.foregroundColor, value: UIColor.systemGreen, range: awayRange)
            }
        }
        
        scoreLabel.attributedText = attributedScore
    }
} 
