import UIKit
import FirebaseFirestore

class TimelineViewController: UIViewController {
    // MARK: - Properties
    private var matches: [Match] = []
    private var selectedMatch: Match?
    private var filteredActions: [Match.Action] = []
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
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let labels = ["#", "Time", "Quarter", "Player Name", "Team", "Action"]
        labels.forEach { title in
            let label = UILabel()
            label.text = title
            label.font = .systemFont(ofSize: 14, weight: .bold)
            label.textAlignment = .center
            stackView.addArrangedSubview(label)
        }
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TimelineCell.self, forCellReuseIdentifier: "TimelineCell")
        tableView.rowHeight = 44
        tableView.tableHeaderView = headerView
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
        title = "Match Timeline"
        
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
            searchBar.heightAnchor.constraint(equalToConstant: 44),
            headerView.heightAnchor.constraint(equalToConstant: 44)
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
                    self?.updateActions()
                }
            }
        }
    }
    
    private func updateActions() {
        guard let match = selectedMatch else { return }
        
        var actions: [Match.Action] = []
        
        // Process home team actions
        if selectedTeam == nil || selectedTeam == "Home" {
            actions.append(contentsOf: match.home.actions)
        }
        
        // Process away team actions
        if selectedTeam == nil || selectedTeam == "Away" {
            actions.append(contentsOf: match.away.actions)
        }
        
        // Filter by search text if any
        if let searchText = searchBar.text, !searchText.isEmpty {
            actions = actions.filter { $0.playerName.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Sort actions by time
        actions.sort { $0.time < $1.time }
        
        filteredActions = actions
        tableView.reloadData()
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
        updateActions()
    }
}

// MARK: - UIPickerViewDelegate & UIPickerViewDataSource
extension TimelineViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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
        updateActions()
    }
}

// MARK: - UISearchBarDelegate
extension TimelineViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateActions()
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension TimelineViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredActions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineCell", for: indexPath) as! TimelineCell
        let action = filteredActions[indexPath.row]
        
        // Determine which team the action belongs to
        let isHomeTeam = selectedMatch?.home.actions.contains(where: { $0.time == action.time && $0.playerName == action.playerName }) ?? false
        let teamName = isHomeTeam ? selectedMatch?.home.name : selectedMatch?.away.name
        
        cell.configure(
            positionNumber: action.positionNumber,
            time: action.time,
            quarter: action.actionQuarter,
            playerName: action.playerName,
            teamName: teamName ?? "",
            action: action.action
        )
        
        return cell
    }
}

// MARK: - TimelineCell
class TimelineCell: UITableViewCell {
    private let positionNumberLabel = UILabel()
    private let timeLabel = UILabel()
    private let quarterLabel = UILabel()
    private let playerNameLabel = UILabel()
    private let teamLabel = UILabel()
    private let actionLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        [positionNumberLabel, timeLabel, quarterLabel, playerNameLabel, teamLabel, actionLabel].forEach { label in
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 14)
            stackView.addArrangedSubview(label)
        }
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
    
    func configure(positionNumber: Int, time: String, quarter: Int, playerName: String, teamName: String, action: String) {
        positionNumberLabel.text = "\(positionNumber)"
        timeLabel.text = "\(time)"
        quarterLabel.text = "Q\(quarter)"
        playerNameLabel.text = playerName
        teamLabel.text = teamName
        actionLabel.text = action
    }
} 
