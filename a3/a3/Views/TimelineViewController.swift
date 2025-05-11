import UIKit
import FirebaseFirestore

class TimelineViewController: UIViewController {
    // MARK: - Properties
    private var match: Match!
    private var tableView: UITableView!
    private let db = Firestore.firestore()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadMatchData()
    }
    
    // MARK: - Setup Methods
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TimelineCell")
        view.addSubview(tableView)
    }
    
    // MARK: - Configuration
    func configure(with match: Match) {
        self.match = match
        tableView.reloadData()
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
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4 // Quarters
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Quarter \(section + 1)"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let quarterActions = (match.home.actions + match.away.actions).filter { $0.actionQuarter == section + 1 }
        return quarterActions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineCell", for: indexPath)
        
        let quarterActions = (match.home.actions + match.away.actions)
            .filter { $0.actionQuarter == indexPath.section + 1 }
            .sorted { $0.time < $1.time }
        
        let action = quarterActions[indexPath.row]
        cell.textLabel?.text = "\(action.time) - \(action.playerName) (\(action.action))"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
} 
