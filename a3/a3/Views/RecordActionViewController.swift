import UIKit
import FirebaseFirestore

class RecordActionViewController: UIViewController {
    // MARK: - Properties
    var match: Match?
    private var selectedHomePlayerIndex: Int?
    private var selectedAwayPlayerIndex: Int?
    private var selectedTeam: String?
    private var currentQuarter = 1
    private var startTime: TimeInterval = 0
    private var lastAction: Match.Action?
    private var matchStarted = false
    private var timer: Timer?
    private let db = Firestore.firestore()
    
    // MARK: - UI Elements
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var homeTeamNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 30)
        label.textAlignment = .left
        return label
    }()
    
    private lazy var awayTeamNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 30)
        label.textAlignment = .right
        return label
    }()
    
    private lazy var homeTeamScoreLabel: UILabel = {
        let label = UILabel()
        label.text = "0 . 0 (0)"
        label.font = .systemFont(ofSize: 30)
        label.textAlignment = .left
        return label
    }()
    
    private lazy var awayTeamScoreLabel: UILabel = {
        let label = UILabel()
        label.text = "0 . 0 (0)"
        label.font = .systemFont(ofSize: 30)
        label.textAlignment = .right
        return label
    }()
    
    private lazy var homeTeamTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HomePlayerCell")
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.black.cgColor
        return tableView
    }()
    
    private lazy var awayTeamTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AwayPlayerCell")
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.black.cgColor
        return tableView
    }()
    
    private lazy var startEndQuarterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("START MATCH", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 19)
        button.backgroundColor = UIColor(red: 0.2, green: 0.51, blue: 0.74, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(startEndQuarterButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var viewStatsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("VIEW STATS", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 19)
        button.backgroundColor = UIColor(red: 0.2, green: 0.51, blue: 0.74, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(viewStatsButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var endMatchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("END MATCH", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 19)
        button.backgroundColor = UIColor(red: 0.2, green: 0.51, blue: 0.74, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(endMatchButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var kickButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("KICK", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        button.backgroundColor = UIColor(red: 0.2, green: 0.51, blue: 0.74, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(kickButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var handButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("HAND", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        button.backgroundColor = UIColor(red: 0.2, green: 0.51, blue: 0.74, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(handButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var markButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("MARK", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        button.backgroundColor = UIColor(red: 0.2, green: 0.51, blue: 0.74, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(markButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var tackleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("TACKLE", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        button.backgroundColor = UIColor(red: 0.2, green: 0.51, blue: 0.74, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(tackleButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var goalButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("GOAL", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        button.backgroundColor = UIColor(red: 0.2, green: 0.51, blue: 0.74, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(goalButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var behindButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("BEHIND", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        button.backgroundColor = UIColor(red: 0.2, green: 0.51, blue: 0.74, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(behindButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMatchData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add subviews
        view.addSubview(timeLabel)
        view.addSubview(homeTeamNameLabel)
        view.addSubview(awayTeamNameLabel)
        view.addSubview(homeTeamScoreLabel)
        view.addSubview(awayTeamScoreLabel)
        view.addSubview(homeTeamTableView)
        view.addSubview(awayTeamTableView)
        view.addSubview(startEndQuarterButton)
        view.addSubview(viewStatsButton)
        view.addSubview(endMatchButton)
        view.addSubview(kickButton)
        view.addSubview(handButton)
        view.addSubview(markButton)
        view.addSubview(tackleButton)
        view.addSubview(goalButton)
        view.addSubview(behindButton)
        
        // Configure table views
        homeTeamTableView.translatesAutoresizingMaskIntoConstraints = false
        awayTeamTableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Register cells
        homeTeamTableView.register(UITableViewCell.self, forCellReuseIdentifier: "HomePlayerCell")
        awayTeamTableView.register(UITableViewCell.self, forCellReuseIdentifier: "AwayPlayerCell")
        
        // Setup constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        // Time label
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Team name labels
        homeTeamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        awayTeamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            homeTeamNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            homeTeamNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            awayTeamNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            awayTeamNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        // Score labels
        homeTeamScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        awayTeamScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            homeTeamScoreLabel.topAnchor.constraint(equalTo: homeTeamNameLabel.bottomAnchor, constant: 8),
            homeTeamScoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            awayTeamScoreLabel.topAnchor.constraint(equalTo: awayTeamNameLabel.bottomAnchor, constant: 8),
            awayTeamScoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        // Team tables
        homeTeamTableView.translatesAutoresizingMaskIntoConstraints = false
        awayTeamTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            homeTeamTableView.topAnchor.constraint(equalTo: startEndQuarterButton.bottomAnchor, constant: 8),
            homeTeamTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            homeTeamTableView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
            homeTeamTableView.bottomAnchor.constraint(equalTo: kickButton.topAnchor, constant: -16),
            
            awayTeamTableView.topAnchor.constraint(equalTo: endMatchButton.bottomAnchor, constant: 8),
            awayTeamTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            awayTeamTableView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
            awayTeamTableView.bottomAnchor.constraint(equalTo: markButton.topAnchor, constant: -16)
        ])
        
        // Top buttons
        startEndQuarterButton.translatesAutoresizingMaskIntoConstraints = false
        viewStatsButton.translatesAutoresizingMaskIntoConstraints = false
        endMatchButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startEndQuarterButton.topAnchor.constraint(equalTo: homeTeamScoreLabel.bottomAnchor, constant: 16),
            startEndQuarterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startEndQuarterButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            startEndQuarterButton.heightAnchor.constraint(equalToConstant: 80),
            
            viewStatsButton.topAnchor.constraint(equalTo: homeTeamScoreLabel.bottomAnchor, constant: 16),
            viewStatsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            viewStatsButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            viewStatsButton.heightAnchor.constraint(equalToConstant: 80),
            
            endMatchButton.topAnchor.constraint(equalTo: homeTeamScoreLabel.bottomAnchor, constant: 16),
            endMatchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            endMatchButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            endMatchButton.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Action buttons
        kickButton.translatesAutoresizingMaskIntoConstraints = false
        handButton.translatesAutoresizingMaskIntoConstraints = false
        markButton.translatesAutoresizingMaskIntoConstraints = false
        tackleButton.translatesAutoresizingMaskIntoConstraints = false
        goalButton.translatesAutoresizingMaskIntoConstraints = false
        behindButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            kickButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            kickButton.bottomAnchor.constraint(equalTo: tackleButton.topAnchor, constant: -8),
            kickButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            kickButton.heightAnchor.constraint(equalToConstant: 80),
            
            handButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handButton.bottomAnchor.constraint(equalTo: goalButton.topAnchor, constant: -8),
            handButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            handButton.heightAnchor.constraint(equalToConstant: 80),
            
            markButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            markButton.bottomAnchor.constraint(equalTo: behindButton.topAnchor, constant: -8),
            markButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            markButton.heightAnchor.constraint(equalToConstant: 80),
            
            tackleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tackleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            tackleButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            tackleButton.heightAnchor.constraint(equalToConstant: 80),
            
            goalButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            goalButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            goalButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            goalButton.heightAnchor.constraint(equalToConstant: 80),
            
            behindButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            behindButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            behindButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            behindButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    // MARK: - Data Methods
    private func loadMatchData() {
        guard let match = match else { return }
        
        print("Loading match data:")
        print("Home team players count: \(match.home.players.count)")
        print("Away team players count: \(match.away.players.count)")
        
        // Debug print for home team players
        print("\nHome Team Players:")
        match.home.players.forEach { player in
            print("Player: \(player.playerName), Number: \(player.positionNumber), Has Image: \(player.image != nil)")
        }
        
        // Debug print for away team players
        print("\nAway Team Players:")
        match.away.players.forEach { player in
            print("Player: \(player.playerName), Number: \(player.positionNumber), Has Image: \(player.image != nil)")
        }
        
        // Set team names
        homeTeamNameLabel.text = match.home.name
        awayTeamNameLabel.text = match.away.name
        
        // Update button states
        if matchStarted {
            startEndQuarterButton.setTitle("END QUARTER", for: .normal)
            startTimer()
        } else {
            startEndQuarterButton.setTitle("START MATCH", for: .normal)
        }
        
        currentQuarter = match.currentQuarter
        startTime = match.startTime
        lastAction = match.lastAction
        matchStarted = match.matchStarted
        
        calculateScore()
        
        // Ensure table views are properly configured
        homeTeamTableView.delegate = self
        homeTeamTableView.dataSource = self
        awayTeamTableView.delegate = self
        awayTeamTableView.dataSource = self
        
        // Reload table views
        DispatchQueue.main.async { [weak self] in
            self?.homeTeamTableView.reloadData()
            self?.awayTeamTableView.reloadData()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTime()
        }
    }
    
    private func updateTime() {
        let elapsedTime = Date().timeIntervalSince1970 - startTime
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        timeLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func calculateScore() {
        guard let match = match else { return }
        
        let homeActions = match.home.actions.filter { $0.actionQuarter == currentQuarter }
        let awayActions = match.away.actions.filter { $0.actionQuarter == currentQuarter }
        
        let homeGoals = homeActions.filter { $0.action == "goal" }.count
        let homeBehinds = homeActions.filter { $0.action == "behind" }.count
        let awayGoals = awayActions.filter { $0.action == "goal" }.count
        let awayBehinds = awayActions.filter { $0.action == "behind" }.count
        
        let homeTotal = homeGoals * 6 + homeBehinds
        let awayTotal = awayGoals * 6 + awayBehinds
        
        homeTeamScoreLabel.text = "\(homeGoals) . \(homeBehinds) (\(homeTotal))"
        awayTeamScoreLabel.text = "\(awayGoals) . \(awayBehinds) (\(awayTotal))"
        
        if homeTotal > awayTotal {
            homeTeamScoreLabel.textColor = .green
            awayTeamScoreLabel.textColor = .red
        } else if homeTotal < awayTotal {
            homeTeamScoreLabel.textColor = .red
            awayTeamScoreLabel.textColor = .green
        } else {
            homeTeamScoreLabel.textColor = .black
            awayTeamScoreLabel.textColor = .black
        }
    }
    
    // MARK: - Action Methods
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func teamManagementButtonTapped(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let teamManagementVC = storyboard.instantiateViewController(withIdentifier: "TeamManagementViewController") as? TeamManagementViewController {
            teamManagementVC.match = match
            navigationController?.pushViewController(teamManagementVC, animated: true)
        }
    }
    
    @objc private func startEndQuarterButtonTapped() {
        if matchStarted {
            endQuarter()
        } else {
            startMatch()
        }
    }
    
    @objc private func viewStatsButtonTapped() {
        let statsComparisonVC = StatsComparisonViewController()
        statsComparisonVC.match = match
        navigationController?.pushViewController(statsComparisonVC, animated: true)
    }
    
    @objc private func endMatchButtonTapped() {
        endMatch()
    }
    
    @objc private func kickButtonTapped() {
        recordAction("kick")
    }
    
    @objc private func handButtonTapped() {
        recordAction("hand")
    }
    
    @objc private func markButtonTapped() {
        recordAction("mark")
    }
    
    @objc private func tackleButtonTapped() {
        recordAction("tackle")
    }
    
    @objc private func goalButtonTapped() {
        guard let selectedPlayer = getSelectedPlayer() else {
            showAlert(message: "Please select a player to record the action")
            return
        }
        
        if let lastAction = lastAction,
           lastAction.action == "kick",
           lastAction.positionNumber == selectedPlayer.positionNumber,
           lastAction.actionTeam == selectedTeam {
            recordAction("goal")
        } else {
            showAlert(message: "Goal can only be recorded after a Kick with a same player in a same team!")
        }
    }
    
    @objc private func behindButtonTapped() {
        guard let selectedPlayer = getSelectedPlayer() else {
            showAlert(message: "Please select a player to record the action")
            return
        }
        
        if let lastAction = lastAction,
           (lastAction.action == "kick" || lastAction.action == "hand"),
           lastAction.positionNumber == selectedPlayer.positionNumber,
           lastAction.actionTeam == selectedTeam {
            recordAction("behind")
        } else {
            showAlert(message: "Behind can only be recorded after a Kick or a Handball with a same player in a same team!")
        }
    }
    
    private func startMatch() {
        guard let match = match else { return }
        
        matchStarted = true
        startTime = Date().timeIntervalSince1970
        startEndQuarterButton.setTitle("END QUARTER", for: .normal)
        startTimer()
        
        updateMatchData()
    }
    
    private func endQuarter() {
        guard let match = match else { return }
        
        if currentQuarter < 4 {
            currentQuarter += 1
            startTime = Date().timeIntervalSince1970
            startTimer()
        } else {
            endMatch()
        }
        
        updateMatchData()
    }
    
    private func endMatch() {
        guard var match = match else { return }
        
        timer?.invalidate()
        timer = nil
        matchStarted = false
        
        // Calculate final scores and determine winner
        let homeActions = match.home.actions
        let awayActions = match.away.actions
        
        let homeGoals = homeActions.filter { $0.action == "goal" }.count
        let homeBehinds = homeActions.filter { $0.action == "behind" }.count
        let awayGoals = awayActions.filter { $0.action == "goal" }.count
        let awayBehinds = awayActions.filter { $0.action == "behind" }.count
        
        let homeTotal = homeGoals * 6 + homeBehinds
        let awayTotal = awayGoals * 6 + awayBehinds
        
        let winner = homeTotal > awayTotal ? match.home.name : (awayTotal > homeTotal ? match.away.name : "Draw")
        
        // Create a new match instance with updated values
        var updatedMatch = match
        updatedMatch.status = "Ended"
        updatedMatch.winner = winner

        // Update the match property
        self.match = updatedMatch
        
        updateMatchData()
        navigationController?.popViewController(animated: true)
    }
    
    private func recordAction(_ actionType: String) {
        guard var match = match else { return }
        
        if !matchStarted {
            showAlert(message: "Please start the match before recording actions")
            return
        }
        
        guard let selectedPlayer = getSelectedPlayer() else {
            showAlert(message: "Please select a player to record the action")
            return
        }
        
        if selectedPlayer.injuryStatus {
            showAlert(message: "\(selectedPlayer.playerName) is injured, action cannot be recorded")
            return
        }
        
        let elapsedTime = Date().timeIntervalSince1970 - startTime
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        
        let action = Match.Action(
            action: actionType,
            actionTeam: selectedTeam!,
            time: timeString,
            playerName: selectedPlayer.playerName,
            positionNumber: selectedPlayer.positionNumber,
            actionQuarter: currentQuarter
        )
        
        // Create new home and away teams with updated actions
        var updatedHomeTeam = match.home
        var updatedAwayTeam = match.away
        
        if selectedTeam == "HOME" {
            updatedHomeTeam.actions.append(action)
        } else {
            updatedAwayTeam.actions.append(action)
        }
        
        // Create a new match instance with updated teams
        var updatedMatch = match
        updatedMatch.status = "Ended"
        
        // Update the match property
        self.match = updatedMatch
        
        lastAction = action
        updateMatchData()
        calculateScore()
        
        showAlert(message: "\(actionType.capitalized) action for \(selectedPlayer.playerName) (\(selectedPlayer.positionNumber)) recorded successfully!")
    }
    
    private func getSelectedPlayer() -> Player? {
        if selectedTeam == "HOME", let index = selectedHomePlayerIndex {
            return match?.home.players[index]
        } else if selectedTeam == "AWAY", let index = selectedAwayPlayerIndex {
            return match?.away.players[index]
        }
        return nil
    }
    
    private func updateMatchData() {
        guard let match = match, let matchId = match.id else { return }
        
        let matchData: [String: Any] = [
            "currentQuarter": currentQuarter,
            "startTime": startTime,
            "matchStarted": matchStarted,
            "lastAction": lastAction.map { [
                "action": $0.action,
                "actionTeam": $0.actionTeam,
                "time": $0.time,
                "playerName": $0.playerName,
                "positionNumber": $0.positionNumber,
                "actionQuarter": $0.actionQuarter
            ] } ?? NSNull(),
            "home.actions": match.home.actions.map { [
                "action": $0.action,
                "actionTeam": $0.actionTeam,
                "time": $0.time,
                "playerName": $0.playerName,
                "positionNumber": $0.positionNumber,
                "actionQuarter": $0.actionQuarter
            ] },
            "away.actions": match.away.actions.map { [
                "action": $0.action,
                "actionTeam": $0.actionTeam,
                "time": $0.time,
                "playerName": $0.playerName,
                "positionNumber": $0.positionNumber,
                "actionQuarter": $0.actionQuarter
            ] },
            "status": match.status,
            "winner": match.winner ?? NSNull()
        ]
        
        db.collection("matches").document(matchId).updateData(matchData) { [weak self] error in
            if let error = error {
                self?.showAlert(message: "Error updating match data: \(error.localizedDescription)")
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension RecordActionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == homeTeamTableView {
            return match?.home.players.count ?? 0
        } else if tableView == awayTeamTableView {
            return match?.away.players.count ?? 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        if tableView == homeTeamTableView {
            cell = tableView.dequeueReusableCell(withIdentifier: "HomePlayerCell", for: indexPath)
            if let player = match?.home.players[indexPath.row] {
                var content = cell.defaultContentConfiguration()
                content.text = "\(player.playerName) (\(player.positionNumber))"
                if player.injuryStatus {
                    content.textProperties.color = .red
                }
                cell.contentConfiguration = content
                cell.backgroundColor = selectedHomePlayerIndex == indexPath.row ? .lightGray : .white
            }
        } else if tableView == awayTeamTableView {
            cell = tableView.dequeueReusableCell(withIdentifier: "AwayPlayerCell", for: indexPath)
            if let player = match?.away.players[indexPath.row] {
                var content = cell.defaultContentConfiguration()
                content.text = "\(player.playerName) (\(player.positionNumber))"
                if player.injuryStatus {
                    content.textProperties.color = .red
                }
                cell.contentConfiguration = content
                cell.backgroundColor = selectedAwayPlayerIndex == indexPath.row ? .lightGray : .white
            }
        } else {
            cell = UITableViewCell()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == homeTeamTableView {
            selectedHomePlayerIndex = indexPath.row
            selectedAwayPlayerIndex = nil
            selectedTeam = "HOME"
            homeTeamTableView.reloadData()
            awayTeamTableView.reloadData()
        } else if tableView == awayTeamTableView {
            selectedHomePlayerIndex = nil
            selectedAwayPlayerIndex = indexPath.row
            selectedTeam = "AWAY"
            homeTeamTableView.reloadData()
            awayTeamTableView.reloadData()
        }
    }
} 
