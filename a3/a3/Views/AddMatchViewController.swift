import UIKit
import FirebaseFirestore

class AddMatchViewController: UIViewController {
    private let db = Firestore.firestore()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "ADD NEW MATCH"
        label.font = .systemFont(ofSize: 30)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let homeTeamLabel: UILabel = {
        let label = UILabel()
        label.text = "Home Team"
        label.font = .systemFont(ofSize: 28)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let awayTeamLabel: UILabel = {
        let label = UILabel()
        label.text = "Away Team"
        label.font = .systemFont(ofSize: 28)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let homeTeamTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter home team name"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let awayTeamTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter away team name"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 28)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "arrow.backward")
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add subviews
        view.addSubview(titleLabel)
        view.addSubview(backButton)
        view.addSubview(homeTeamLabel)
        view.addSubview(awayTeamLabel)
        view.addSubview(homeTeamTextField)
        view.addSubview(awayTeamTextField)
        view.addSubview(saveButton)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Title label
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Back button
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 50),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Home team label
            homeTeamLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            homeTeamLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            // Away team label
            awayTeamLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            awayTeamLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Home team text field
            homeTeamTextField.topAnchor.constraint(equalTo: homeTeamLabel.bottomAnchor, constant: 16),
            homeTeamTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            homeTeamTextField.widthAnchor.constraint(equalToConstant: 161),
            homeTeamTextField.heightAnchor.constraint(equalToConstant: 69),
            
            // Away team text field
            awayTeamTextField.topAnchor.constraint(equalTo: awayTeamLabel.bottomAnchor, constant: 16),
            awayTeamTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            awayTeamTextField.widthAnchor.constraint(equalToConstant: 171),
            awayTeamTextField.heightAnchor.constraint(equalToConstant: 68),
            
            // Save button
            saveButton.topAnchor.constraint(equalTo: homeTeamTextField.bottomAnchor, constant: 16),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let homeTeamName = homeTeamTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let awayTeamName = awayTeamTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !homeTeamName.isEmpty,
              !awayTeamName.isEmpty else {
            showAlert(message: "Please enter both team names")
            return
        }
        
        // Generate a unique ID for the match
        let matchID = UUID().uuidString
        let currentDate = Date()
        let currentTimeInterval = currentDate.timeIntervalSince1970
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: currentDate)
        
        // Create new match object
        let newMatch = Match(
            home: Match.Team(name: homeTeamName, players: [], actions: []),
            away: Match.Team(name: awayTeamName, players: [], actions: []),
            status: "New",
            currentQuarter: 1,
            startTime: currentTimeInterval,
            lastAction: nil,
            matchStarted: false,
            date: dateString,
            winner: ""
        )
        
        // Convert Match object to dictionary
        let matchData: [String: Any] = [
            "id": newMatch.id ?? "",
            "home": [
                "name": newMatch.home.name,
                "players": newMatch.home.players.map { player in
                    return [
                        "id": player.id ?? "",
                        "playerName": player.playerName,
                        "positionNumber": player.positionNumber,
                        "image": player.image,
                        "injuryStatus": player.injuryStatus
                    ]
                },
                "actions": newMatch.home.actions.map { action in
                    return [
                        "action": action.action,
                        "actionTeam": action.actionTeam,
                        "time": action.time,
                        "playerName": action.playerName,
                        "positionNumber": action.positionNumber,
                        "actionQuarter": action.actionQuarter
                    ]
                }
            ],
            "away": [
                "name": newMatch.away.name,
                "players": newMatch.away.players.map { player in
                    return [
                        "id": player.id ?? "",
                        "playerName": player.playerName,
                        "positionNumber": player.positionNumber,
                        "image": player.image,
                        "injuryStatus": player.injuryStatus
                    ]
                },
                "actions": newMatch.away.actions.map { action in
                    return [
                        "action": action.action,
                        "actionTeam": action.actionTeam,
                        "time": action.time,
                        "playerName": action.playerName,
                        "positionNumber": action.positionNumber,
                        "actionQuarter": action.actionQuarter
                    ]
                }
            ],
            "status": newMatch.status,
            "currentQuarter": newMatch.currentQuarter,
            "startTime": newMatch.startTime,
            "lastAction": newMatch.lastAction.map { action in
                return [
                    "action": action.action,
                    "actionTeam": action.actionTeam,
                    "time": action.time,
                    "playerName": action.playerName,
                    "positionNumber": action.positionNumber,
                    "actionQuarter": action.actionQuarter
                ]
            } ?? NSNull(),
            "matchStarted": newMatch.matchStarted,
            "date": newMatch.date
        ]
        
        // Add to Firestore
        db.collection("matches").document(matchID).setData(matchData) { [weak self] error in
            if let error = error {
                self?.showAlert(message: "Error adding match: \(error.localizedDescription)")
            } else {
                self?.showAlert(message: "Match added successfully") { _ in
                    self?.dismiss(animated: true)
                }
            }
        }
    }


    
    private func showAlert(message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
        present(alert, animated: true)
    }
} 
