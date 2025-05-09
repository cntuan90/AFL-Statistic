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
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "STATS RECORDING"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00:00"
        label.font = .systemFont(ofSize: 30)
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlayerCell")
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.black.cgColor
        return tableView
    }()
    
    private lazy var awayTeamTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlayerCell")
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
        view.backgroundColor = .white
        
        // Add subviews
        view.addSubview(backButton)
        view.addSubview(titleLabel)
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
        
        // Setup constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        // Back button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 50),
            backButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Time label
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Team name labels
        homeTeamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        awayTeamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            homeTeamNameLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            homeTeamNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            awayTeamNameLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
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
            homeTeamTableView.topAnchor.constraint(equalTo: homeTeamScoreLabel.bottomAnchor, constant: 8),
            homeTeamTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            homeTeamTableView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
            homeTeamTableView.bottomAnchor.constraint(equalTo: kickButton.topAnchor, constant: -16),
            
            awayTeamTableView.topAnchor.constraint(equalTo: awayTeamScoreLabel.bottomAnchor, constant: 8),
            awayTeamTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            awayTeamTableView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
            awayTeamTableView.bottomAnchor.constraint(equalTo: kickButton.topAnchor, constant: -16)
        ])
        
        // Top buttons
        startEndQuarterButton.translatesAutoresizingMaskIntoConstraints = false
        viewStatsButton.translatesAutoresizingMaskIntoConstraints = false
        endMatchButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startEndQuarterButton.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            startEndQuarterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startEndQuarterButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            startEndQuarterButton.heightAnchor.constraint(equalToConstant: 80),
            
            viewStatsButton.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            viewStatsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            viewStatsButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            viewStatsButton.heightAnchor.constraint(equalToConstant: 80),
            
            endMatchButton.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
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
        
        homeTeamNameLabel.text = match.home.name
        awayTeamNameLabel.text = match.away.name
        
        currentQuarter = match.currentQuarter
        startTime = match.startTime
        lastAction = match.lastAction
        matchStarted = match.matchStarted
        
        if matchStarted {
            startEndQuarterButton.setTitle("END QUARTER", for: .normal)
            startTimer()
        }
        
        calculateScore()
        homeTeamTableView.reloadData()
        awayTeamTableView.reloadData()
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
        } else {
            return match?.away.players.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath)
        
        let player: Player
        if tableView == homeTeamTableView {
            player = match!.home.players[indexPath.row]
            cell.backgroundColor = selectedHomePlayerIndex == indexPath.row ? .lightGray : .white
        } else {
            player = match!.away.players[indexPath.row]
            cell.backgroundColor = selectedAwayPlayerIndex == indexPath.row ? .lightGray : .white
        }
        
        var content = cell.defaultContentConfiguration()
        content.text = "\(player.playerName) (\(player.positionNumber))"
        if player.injuryStatus {
            content.textProperties.color = .red
        }
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == homeTeamTableView {
            selectedHomePlayerIndex = indexPath.row
            selectedAwayPlayerIndex = nil
            selectedTeam = "HOME"
        } else {
            selectedHomePlayerIndex = nil
            selectedAwayPlayerIndex = indexPath.row
            selectedTeam = "AWAY"
        }
        
        homeTeamTableView.reloadData()
        awayTeamTableView.reloadData()
    }
} 
