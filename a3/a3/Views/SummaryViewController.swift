import UIKit
import FirebaseFirestore

class SummaryViewController: UIViewController {
    // MARK: - Properties
    var match: Match?
    private let db = Firestore.firestore()
    
    // MARK: - UI Elements
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .white
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
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
        setupUI()
        loadMatchData()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .white
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(matchInfoView)
        matchInfoView.addSubview(homeTeamLabel)
        matchInfoView.addSubview(awayTeamLabel)
        matchInfoView.addSubview(scoreLabel)
        matchInfoView.addSubview(dateLabel)
        contentView.addSubview(statsTableView)
        
        // Setup constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Match info view
        matchInfoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            matchInfoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            matchInfoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            matchInfoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        // Team labels
        homeTeamLabel.translatesAutoresizingMaskIntoConstraints = false
        awayTeamLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            homeTeamLabel.topAnchor.constraint(equalTo: matchInfoView.topAnchor, constant: 16),
            homeTeamLabel.leadingAnchor.constraint(equalTo: matchInfoView.leadingAnchor, constant: 16),
            homeTeamLabel.trailingAnchor.constraint(equalTo: matchInfoView.trailingAnchor, constant: -16),
            
            awayTeamLabel.topAnchor.constraint(equalTo: homeTeamLabel.bottomAnchor, constant: 8),
            awayTeamLabel.leadingAnchor.constraint(equalTo: matchInfoView.leadingAnchor, constant: 16),
            awayTeamLabel.trailingAnchor.constraint(equalTo: matchInfoView.trailingAnchor, constant: -16)
        ])
        
        // Score label
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: awayTeamLabel.bottomAnchor, constant: 16),
            scoreLabel.leadingAnchor.constraint(equalTo: matchInfoView.leadingAnchor, constant: 16),
            scoreLabel.trailingAnchor.constraint(equalTo: matchInfoView.trailingAnchor, constant: -16)
        ])
        
        // Date label
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: matchInfoView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: matchInfoView.trailingAnchor, constant: -16),
            dateLabel.bottomAnchor.constraint(equalTo: matchInfoView.bottomAnchor, constant: -16)
        ])
        
        // Stats table view
        statsTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statsTableView.topAnchor.constraint(equalTo: matchInfoView.bottomAnchor, constant: 16),
            statsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
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
