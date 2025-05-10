import UIKit
import FirebaseFirestore

class TimelineViewController: UIViewController {
    // MARK: - Properties
    private var match: Match?
    private let db = Firestore.firestore()
    
    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TimelineCell")
        tableView.separatorStyle = .none
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
        view.addSubview(tableView)
        
        // Setup constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Data Methods
    private func loadMatchData() {
        // TODO: Load match data from Firestore
        // For now, using sample data
        let homeTeam = Match.Team(name: "Home Team", players: [])
        let awayTeam = Match.Team(name: "Away Team", players: [])
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        match = Match(home: homeTeam, away: awayTeam, status: "Not Started", currentQuarter: 1, startTime: Date().timeIntervalSince1970, lastAction: nil, matchStarted: false, date: dateString, winner: nil)
        
        tableView.reloadData()
    }
    
    private func getAllActions() -> [Match.Action] {
        guard let match = match else { return [] }
        
        var allActions = match.home.actions + match.away.actions
        allActions.sort { $0.time < $1.time }
        return allActions
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension TimelineViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getAllActions().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineCell", for: indexPath)
        
        let actions = getAllActions()
        let action = actions[indexPath.row]
        
        // Create a container view for the cell content
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.lightGray.cgColor
        containerView.layer.cornerRadius = 8
        
        // Create a vertical line for the timeline
        let timelineLine = UIView()
        timelineLine.backgroundColor = UIColor(red: 0.2, green: 0.51, blue: 0.74, alpha: 1.0)
        
        // Create a circle for the timeline point
        let timelinePoint = UIView()
        timelinePoint.backgroundColor = UIColor(red: 0.2, green: 0.51, blue: 0.74, alpha: 1.0)
        timelinePoint.layer.cornerRadius = 6
        
        // Create labels for the action details
        let timeLabel = UILabel()
        timeLabel.text = action.time
        timeLabel.font = .systemFont(ofSize: 14)
        timeLabel.textColor = .gray
        
        let actionLabel = UILabel()
        actionLabel.text = "\(action.playerName) (\(action.positionNumber)) - \(action.action.capitalized)"
        actionLabel.font = .systemFont(ofSize: 16)
        
        let teamLabel = UILabel()
        teamLabel.text = action.actionTeam
        teamLabel.font = .systemFont(ofSize: 14)
        teamLabel.textColor = .gray
        
        // Add subviews
        containerView.addSubview(timelineLine)
        containerView.addSubview(timelinePoint)
        containerView.addSubview(timeLabel)
        containerView.addSubview(actionLabel)
        containerView.addSubview(teamLabel)
        
        // Setup constraints for the container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
        ])
        
        // Setup constraints for the timeline elements
        timelineLine.translatesAutoresizingMaskIntoConstraints = false
        timelinePoint.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        actionLabel.translatesAutoresizingMaskIntoConstraints = false
        teamLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timelineLine.topAnchor.constraint(equalTo: containerView.topAnchor),
            timelineLine.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            timelineLine.widthAnchor.constraint(equalToConstant: 2),
            timelineLine.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            timelinePoint.centerXAnchor.constraint(equalTo: timelineLine.centerXAnchor),
            timelinePoint.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            timelinePoint.widthAnchor.constraint(equalToConstant: 12),
            timelinePoint.heightAnchor.constraint(equalToConstant: 12),
            
            timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: timelinePoint.trailingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            actionLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4),
            actionLabel.leadingAnchor.constraint(equalTo: timelinePoint.trailingAnchor, constant: 16),
            actionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            teamLabel.topAnchor.constraint(equalTo: actionLabel.bottomAnchor, constant: 4),
            teamLabel.leadingAnchor.constraint(equalTo: timelinePoint.trailingAnchor, constant: 16),
            teamLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            teamLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
        
        cell.contentView.addSubview(containerView)
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
} 
