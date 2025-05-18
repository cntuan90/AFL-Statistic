import UIKit
import FirebaseFirestore

class SummaryViewController: UIViewController {
    // MARK: - Properties
    private var matches: [Match] = []
    private var selectedMatch: Match?
    private var filteredActions: [(player: Player, stats: PlayerStats)] = []
    private var selectedTeam: String?
    private let db = Firestore.firestore()
    
    // MARK: - UI Elements
    private lazy var matchPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    
    private lazy var teamFilterSegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["All Teams", "Home", "Away"])
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(teamFilterChanged), for: .valueChanged)
        return segment
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search player..."
        searchBar.delegate = self
        return searchBar
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PlayerStatsCell.self, forCellReuseIdentifier: "PlayerStatsCell")
        tableView.rowHeight = 44
        return tableView
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMatches()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Match Summary"
        
        // Create stack view for controls
        let controlsStack = UIStackView()
        controlsStack.axis = .vertical
        controlsStack.spacing = 8
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Add controls to stack view
        controlsStack.addArrangedSubview(matchPicker)
        controlsStack.addArrangedSubview(teamFilterSegment)
        controlsStack.addArrangedSubview(searchBar)
        controlsStack.addArrangedSubview(tableView)
        
        view.addSubview(controlsStack)
        
        // Calculate safe area insets
        let window = UIApplication.shared.windows.first
        let bottomPadding = window?.safeAreaInsets.bottom ?? 0
        let tabBarHeight: CGFloat = 49 // Standard tab bar height
        
        NSLayoutConstraint.activate([
            controlsStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            controlsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(bottomPadding + tabBarHeight)),

            matchPicker.heightAnchor.constraint(equalToConstant: 120),
            teamFilterSegment.heightAnchor.constraint(equalToConstant: 40),
            searchBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Data Methods
    private func loadMatches() {
        db.collection("matches").getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print("Error loading matches: \(error)")
                return
            }
            
            self?.matches = snapshot?.documents.compactMap { Match(document: $0) } ?? []
            
            DispatchQueue.main.async {
                self?.matchPicker.reloadAllComponents()
                if let firstMatch = self?.matches.first {
                    self?.selectedMatch = firstMatch
                    self?.updatePlayerStats()
                }
            }
        }
    }
    
    private func updatePlayerStats() {
        guard let match = selectedMatch else { return }
        
        var stats: [(player: Player, stats: PlayerStats)] = []
        
        // Process home team players
        if selectedTeam == nil || selectedTeam == "Home" {
            for player in match.home.players {
                let playerStats = calculatePlayerStats(player: player, actions: match.home.actions)
                stats.append((player: player, stats: playerStats))
            }
        }
        
        // Process away team players
        if selectedTeam == nil || selectedTeam == "Away" {
            for player in match.away.players {
                let playerStats = calculatePlayerStats(player: player, actions: match.away.actions)
                stats.append((player: player, stats: playerStats))
            }
        }
        
        // Filter by search text if any
        if let searchText = searchBar.text, !searchText.isEmpty {
            stats = stats.filter { $0.player.playerName.localizedCaseInsensitiveContains(searchText) }
        }
        
        filteredActions = stats
        tableView.reloadData()
    }
    
    private func calculatePlayerStats(player: Player, actions: [Match.Action]) -> PlayerStats {
        let playerActions = actions.filter { $0.playerName == player.playerName }
        
        return PlayerStats(
            kicks: playerActions.filter { $0.action == "kick" }.count,
            hands: playerActions.filter { $0.action == "hand" }.count,
            marks: playerActions.filter { $0.action == "mark" }.count,
            tackles: playerActions.filter { $0.action == "tackle" }.count,
            goals: playerActions.filter { $0.action == "goal" }.count,
            behinds: playerActions.filter { $0.action == "behind" }.count
        )
    }
    
    // MARK: - Actions
    @objc private func teamFilterChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            selectedTeam = nil
        case 1:
            selectedTeam = "Home"
        case 2:
            selectedTeam = "Away"
        default:
            break
        }
        updatePlayerStats()
    }
}

// MARK: - UIPickerViewDelegate & UIPickerViewDataSource
extension SummaryViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return matches.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let match = matches[row]
        return "\(match.home.name) vs \(match.away.name)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedMatch = matches[row]
        updatePlayerStats()
    }
}

// MARK: - UISearchBarDelegate
extension SummaryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updatePlayerStats()
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension SummaryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredActions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerStatsCell", for: indexPath) as! PlayerStatsCell
        let playerStats = filteredActions[indexPath.row]
        
        cell.configure(
            positionNumber: playerStats.player.positionNumber,
            playerName: playerStats.player.playerName,
            stats: playerStats.stats
        )
        
        return cell
    }
}

// MARK: - PlayerStats
struct PlayerStats {
    let kicks: Int
    let hands: Int
    let marks: Int
    let tackles: Int
    let goals: Int
    let behinds: Int
}

// MARK: - PlayerStatsCell
class PlayerStatsCell: UITableViewCell {
    // MARK: - UI Elements
    private let positionNumberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let playerNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let kicksLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let handsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let marksLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tacklesLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let goalsBehindsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
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
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(positionNumberLabel)
        stackView.addArrangedSubview(playerNameLabel)
        stackView.addArrangedSubview(kicksLabel)
        stackView.addArrangedSubview(handsLabel)
        stackView.addArrangedSubview(marksLabel)
        stackView.addArrangedSubview(tacklesLabel)
        stackView.addArrangedSubview(goalsBehindsLabel)
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
    
    // MARK: - Configuration
    func configure(positionNumber: Int, playerName: String, stats: PlayerStats) {
        positionNumberLabel.text = "\(positionNumber)"
        playerNameLabel.text = playerName
        kicksLabel.text = "\(stats.kicks)"
        handsLabel.text = "\(stats.hands)"
        marksLabel.text = "\(stats.marks)"
        tacklesLabel.text = "\(stats.tackles)"
        goalsBehindsLabel.text = "\(stats.goals).\(stats.behinds)"
    }
} 
