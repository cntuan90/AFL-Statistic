import UIKit
import FirebaseFirestore

class SummaryViewController: UIViewController {
    // MARK: - Properties
    private var match: Match!
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private let db = Firestore.firestore()
    
    // MARK: - UI Elements
    private lazy var matchInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.cornerRadius = 8
        return view
    }()
    
    private lazy var homeTeamLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var awayTeamLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = .gray
        return label
    }()
    
    private lazy var statsTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "StatsCell")
        tableView.isScrollEnabled = false
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.lightGray.cgColor
        tableView.layer.cornerRadius = 8
        return tableView
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        loadMatchData()
    }
    
    // MARK: - Setup Methods
    private func setupScrollView() {
        // Create scroll view
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
        
        // Create content view
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func updateSummary() {
        // Remove existing subviews
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Create summary content
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Add match details
        let matchInfoView = createInfoView(title: "Match Information", items: [
            "Date: \(match.date)",
            "Status: \(match.status)",
            "Winner: \(match.winner ?? "TBD")"
        ])
        stackView.addArrangedSubview(matchInfoView)
        
        // Add team statistics
        let homeStatsView = createInfoView(title: "\(match.home.name) Statistics", items: [
            "Total Actions: \(match.home.actions.count)",
            "Goals: \(match.home.actions.filter { $0.action == "goal" }.count)",
            "Behinds: \(match.home.actions.filter { $0.action == "behind" }.count)"
        ])
        stackView.addArrangedSubview(homeStatsView)
        
        let awayStatsView = createInfoView(title: "\(match.away.name) Statistics", items: [
            "Total Actions: \(match.away.actions.count)",
            "Goals: \(match.away.actions.filter { $0.action == "goal" }.count)",
            "Behinds: \(match.away.actions.filter { $0.action == "behind" }.count)"
        ])
        stackView.addArrangedSubview(awayStatsView)
    }
    
    private func createInfoView(title: String, items: [String]) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        items.forEach { item in
            let label = UILabel()
            label.text = item
            label.font = .systemFont(ofSize: 16)
            stackView.addArrangedSubview(label)
        }
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        return containerView
    }
    
    // MARK: - Data Methods
    private func loadMatchData() {
        // TODO: Load match data from Firestore
        // For now, using sample data
        let homeTeam = Match.Team(name: "Home Team", players: [])
        let awayTeam = Match.Team(name: "Away Team", players: [])
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        match = Match(home: homeTeam, away: awayTeam, status: "Not Started", currentQuarter: 1, startTime: Date().timeIntervalSince1970, lastAction: nil, matchStarted: false, date: formatter.string(from: Date()), winner: nil)
        
        updateUI()
    }
    
    private func updateUI() {
        guard let match = match else { return }
        
        homeTeamLabel.text = match.home.name
        awayTeamLabel.text = match.away.name
        
        let homeGoals = match.home.actions.filter { $0.action == "goal" }.count
        let homeBehinds = match.home.actions.filter { $0.action == "behind" }.count
        let awayGoals = match.away.actions.filter { $0.action == "goal" }.count
        let awayBehinds = match.away.actions.filter { $0.action == "behind" }.count
        
        let homeTotal = homeGoals * 6 + homeBehinds
        let awayTotal = awayGoals * 6 + awayBehinds
        
        scoreLabel.text = "\(homeGoals).\(homeBehinds) (\(homeTotal)) - \(awayGoals).\(awayBehinds) (\(awayTotal))"
        dateLabel.text = match.date
        
        statsTableView.reloadData()
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension SummaryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6 // Kicks, Handballs, Marks, Tackles, Goals, Behinds
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StatsCell", for: indexPath)
        
        guard let match = match else { return cell }
        
        let homeActions = match.home.actions
        let awayActions = match.away.actions
        
        let statType: String
        let homeCount: Int
        let awayCount: Int
        
        switch indexPath.row {
        case 0:
            statType = "Kicks"
            homeCount = homeActions.filter { $0.action == "kick" }.count
            awayCount = awayActions.filter { $0.action == "kick" }.count
        case 1:
            statType = "Handballs"
            homeCount = homeActions.filter { $0.action == "hand" }.count
            awayCount = awayActions.filter { $0.action == "hand" }.count
        case 2:
            statType = "Marks"
            homeCount = homeActions.filter { $0.action == "mark" }.count
            awayCount = awayActions.filter { $0.action == "mark" }.count
        case 3:
            statType = "Tackles"
            homeCount = homeActions.filter { $0.action == "tackle" }.count
            awayCount = awayActions.filter { $0.action == "tackle" }.count
        case 4:
            statType = "Goals"
            homeCount = homeActions.filter { $0.action == "goal" }.count
            awayCount = awayActions.filter { $0.action == "goal" }.count
        case 5:
            statType = "Behinds"
            homeCount = homeActions.filter { $0.action == "behind" }.count
            awayCount = awayActions.filter { $0.action == "behind" }.count
        default:
            return cell
        }
        
        var content = cell.defaultContentConfiguration()
        content.text = "\(statType): \(homeCount) - \(awayCount)"
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

// MARK: - Configuration
extension SummaryViewController {
    func configure(with match: Match) {
        self.match = match
        updateSummary()
    }
} 
