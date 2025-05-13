import UIKit
import FirebaseFirestore

class StatsComparisonViewController: UIViewController {
    // MARK: - Properties
    var match: Match?
    private let db = Firestore.firestore()
    private var selectedHomePlayerIndex: Int?
    private var selectedAwayPlayerIndex: Int?
    private var isQuarterView = false
    private var isWholeTeam = true
    private var selectedQuarter = "All"
    
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
    
    private lazy var homeTeamTableLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var awayTeamTableLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var quarterSegmentedControl: UISegmentedControl = {
        let items = ["All", "Q1", "Q2", "Q3", "Final"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(quarterChanged), for: .valueChanged)
        return control
    }()
    
    private lazy var viewTypeSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.isOn = false
        switchControl.addTarget(self, action: #selector(viewTypeChanged), for: .valueChanged)
        return switchControl
    }()
    
    private lazy var viewTypeLabel: UILabel = {
        let label = UILabel()
        label.text = "Quarter View"
        label.font = .systemFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTypeLabelTapped))
        label.addGestureRecognizer(tapGesture)
        return label
    }()
    
    private lazy var teamTypeSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.isOn = true
        switchControl.addTarget(self, action: #selector(teamTypeChanged), for: .valueChanged)
        return switchControl
    }()
    
    private lazy var teamTypeLabel: UILabel = {
        let label = UILabel()
        label.text = "Whole Team"
        label.font = .systemFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(teamTypeLabelTapped))
        label.addGestureRecognizer(tapGesture)
        return label
    }()
    
    private lazy var statsView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.cornerRadius = 8
        return view
    }()
    
    private lazy var homeTeamTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HomePlayerCell")
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.black.cgColor
        tableView.layer.cornerRadius = 8
        tableView.isUserInteractionEnabled = true
        return tableView
    }()
    
    private lazy var awayTeamTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AwayPlayerCell")
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.black.cgColor
        tableView.layer.cornerRadius = 8
        tableView.isUserInteractionEnabled = true
        return tableView
    }()
    
    // Stats Labels
    private lazy var stat1Label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.text = "Disposals"
        return label
    }()
    
    private lazy var stat2Label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.text = "Marks"
        return label
    }()
    
    private lazy var stat3Label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.text = "Tackles"
        return label
    }()
    
    private lazy var stat4Label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.text = "Score"
        return label
    }()
    
    private lazy var homeStat1Label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.text = "0"
        return label
    }()
    
    private lazy var homeStat2Label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.text = "0"
        return label
    }()
    
    private lazy var homeStat3Label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.text = "0"
        return label
    }()
    
    private lazy var homeStat4Label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.text = "0 . 0 (0)"
        return label
    }()
    
    private lazy var awayStat1Label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.text = "0"
        return label
    }()
    
    private lazy var awayStat2Label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.text = "0"
        return label
    }()
    
    private lazy var awayStat3Label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.text = "0"
        return label
    }()
    
    private lazy var awayStat4Label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.text = "0 . 0 (0)"
        return label
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMatchData()
        
        // Ensure all views are properly configured for interaction
        scrollView.isScrollEnabled = true
        scrollView.isUserInteractionEnabled = true
        contentView.isUserInteractionEnabled = true
        matchInfoView.isUserInteractionEnabled = true
        statsView.isUserInteractionEnabled = true
        
        // Ensure all interactive elements are enabled
        [quarterSegmentedControl, viewTypeSwitch, teamTypeSwitch, homeTeamTableView, awayTeamTableView].forEach {
            $0.isUserInteractionEnabled = true
        }
        
        // Configure tap gestures for labels
        [viewTypeLabel, teamTypeLabel].forEach {
            $0.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: $0 == viewTypeLabel ? #selector(viewTypeLabelTapped) : #selector(teamTypeLabelTapped))
            $0.addGestureRecognizer(tapGesture)
        }
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .white
        title = "Stats Comparison"
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add all interactive elements to contentView
        contentView.addSubview(matchInfoView)
        contentView.addSubview(quarterSegmentedControl)
        contentView.addSubview(viewTypeSwitch)
        contentView.addSubview(viewTypeLabel)
        contentView.addSubview(teamTypeSwitch)
        contentView.addSubview(teamTypeLabel)
        contentView.addSubview(statsView)
        contentView.addSubview(homeTeamTableLabel)
        contentView.addSubview(awayTeamTableLabel)
        contentView.addSubview(homeTeamTableView)
        contentView.addSubview(awayTeamTableView)
        
        // Add stats labels to stats view
        statsView.addSubview(stat1Label)
        statsView.addSubview(stat2Label)
        statsView.addSubview(stat3Label)
        statsView.addSubview(stat4Label)
        statsView.addSubview(homeStat1Label)
        statsView.addSubview(homeStat2Label)
        statsView.addSubview(homeStat3Label)
        statsView.addSubview(homeStat4Label)
        statsView.addSubview(awayStat1Label)
        statsView.addSubview(awayStat2Label)
        statsView.addSubview(awayStat3Label)
        statsView.addSubview(awayStat4Label)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
        
        // Quarter segmented control
        quarterSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            quarterSegmentedControl.topAnchor.constraint(equalTo: matchInfoView.bottomAnchor, constant: 16),
            quarterSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            quarterSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        // View type switch and label
        viewTypeSwitch.translatesAutoresizingMaskIntoConstraints = false
        viewTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewTypeSwitch.topAnchor.constraint(equalTo: quarterSegmentedControl.bottomAnchor, constant: 16),
            viewTypeSwitch.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            viewTypeLabel.centerYAnchor.constraint(equalTo: viewTypeSwitch.centerYAnchor),
            viewTypeLabel.leadingAnchor.constraint(equalTo: viewTypeSwitch.trailingAnchor, constant: 8)
        ])
        
        // Team type switch and label
        teamTypeSwitch.translatesAutoresizingMaskIntoConstraints = false
        teamTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            teamTypeSwitch.topAnchor.constraint(equalTo: quarterSegmentedControl.bottomAnchor, constant: 16),
            teamTypeSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            teamTypeLabel.centerYAnchor.constraint(equalTo: teamTypeSwitch.centerYAnchor),
            teamTypeLabel.trailingAnchor.constraint(equalTo: teamTypeSwitch.leadingAnchor, constant: -8)
        ])
        
        // Stats view
        statsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statsView.topAnchor.constraint(equalTo: viewTypeSwitch.bottomAnchor, constant: 16),
            statsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        // Stats labels
        setupStatsLabelsConstraints()
        
        // Team table labels
        homeTeamTableLabel.translatesAutoresizingMaskIntoConstraints = false
        awayTeamTableLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // Home team label
            homeTeamTableLabel.topAnchor.constraint(equalTo: statsView.bottomAnchor, constant: 16),
            homeTeamTableLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            homeTeamTableLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            
            // Away team label
            awayTeamTableLabel.topAnchor.constraint(equalTo: statsView.bottomAnchor, constant: 16),
            awayTeamTableLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            awayTeamTableLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45)
        ])
        
        // Team tables
        homeTeamTableView.translatesAutoresizingMaskIntoConstraints = false
        awayTeamTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // Home team table
            homeTeamTableView.topAnchor.constraint(equalTo: homeTeamTableLabel.bottomAnchor, constant: 8),
            homeTeamTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            homeTeamTableView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            homeTeamTableView.heightAnchor.constraint(equalToConstant: 400),
            homeTeamTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Away team table
            awayTeamTableView.topAnchor.constraint(equalTo: awayTeamTableLabel.bottomAnchor, constant: 8),
            awayTeamTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            awayTeamTableView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            awayTeamTableView.heightAnchor.constraint(equalToConstant: 400),
            awayTeamTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupStatsLabelsConstraints() {
        // Stat labels
        stat1Label.translatesAutoresizingMaskIntoConstraints = false
        stat2Label.translatesAutoresizingMaskIntoConstraints = false
        stat3Label.translatesAutoresizingMaskIntoConstraints = false
        stat4Label.translatesAutoresizingMaskIntoConstraints = false
        
        // Home stat labels
        homeStat1Label.translatesAutoresizingMaskIntoConstraints = false
        homeStat2Label.translatesAutoresizingMaskIntoConstraints = false
        homeStat3Label.translatesAutoresizingMaskIntoConstraints = false
        homeStat4Label.translatesAutoresizingMaskIntoConstraints = false
        
        // Away stat labels
        awayStat1Label.translatesAutoresizingMaskIntoConstraints = false
        awayStat2Label.translatesAutoresizingMaskIntoConstraints = false
        awayStat3Label.translatesAutoresizingMaskIntoConstraints = false
        awayStat4Label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Stat labels - center aligned with flexible width
            stat1Label.centerYAnchor.constraint(equalTo: homeStat1Label.centerYAnchor),
            stat1Label.centerXAnchor.constraint(equalTo: statsView.centerXAnchor),
            stat1Label.leadingAnchor.constraint(greaterThanOrEqualTo: homeStat1Label.trailingAnchor, constant: 8),
            stat1Label.trailingAnchor.constraint(lessThanOrEqualTo: awayStat1Label.leadingAnchor, constant: -8),
            
            stat2Label.centerYAnchor.constraint(equalTo: homeStat2Label.centerYAnchor),
            stat2Label.centerXAnchor.constraint(equalTo: statsView.centerXAnchor),
            stat2Label.leadingAnchor.constraint(greaterThanOrEqualTo: homeStat2Label.trailingAnchor, constant: 8),
            stat2Label.trailingAnchor.constraint(lessThanOrEqualTo: awayStat2Label.leadingAnchor, constant: -8),
            
            stat3Label.centerYAnchor.constraint(equalTo: homeStat3Label.centerYAnchor),
            stat3Label.centerXAnchor.constraint(equalTo: statsView.centerXAnchor),
            stat3Label.leadingAnchor.constraint(greaterThanOrEqualTo: homeStat3Label.trailingAnchor, constant: 8),
            stat3Label.trailingAnchor.constraint(lessThanOrEqualTo: awayStat3Label.leadingAnchor, constant: -8),
            
            stat4Label.centerYAnchor.constraint(equalTo: homeStat4Label.centerYAnchor),
            stat4Label.centerXAnchor.constraint(equalTo: statsView.centerXAnchor),
            stat4Label.leadingAnchor.constraint(greaterThanOrEqualTo: homeStat4Label.trailingAnchor, constant: 8),
            stat4Label.trailingAnchor.constraint(lessThanOrEqualTo: awayStat4Label.leadingAnchor, constant: -8),
            
            // Home stat labels
            homeStat1Label.topAnchor.constraint(equalTo: statsView.topAnchor, constant: 16),
            homeStat1Label.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 16),
            homeStat1Label.widthAnchor.constraint(equalToConstant: 80),
            
            homeStat2Label.topAnchor.constraint(equalTo: homeStat1Label.bottomAnchor, constant: 16),
            homeStat2Label.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 16),
            homeStat2Label.widthAnchor.constraint(equalToConstant: 80),
            
            homeStat3Label.topAnchor.constraint(equalTo: homeStat2Label.bottomAnchor, constant: 16),
            homeStat3Label.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 16),
            homeStat3Label.widthAnchor.constraint(equalToConstant: 80),
            
            homeStat4Label.topAnchor.constraint(equalTo: homeStat3Label.bottomAnchor, constant: 16),
            homeStat4Label.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 16),
            homeStat4Label.widthAnchor.constraint(equalToConstant: 80),
            homeStat4Label.bottomAnchor.constraint(equalTo: statsView.bottomAnchor, constant: -16),
            
            // Away stat labels
            awayStat1Label.centerYAnchor.constraint(equalTo: homeStat1Label.centerYAnchor),
            awayStat1Label.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -16),
            awayStat1Label.widthAnchor.constraint(equalToConstant: 80),
            
            awayStat2Label.centerYAnchor.constraint(equalTo: homeStat2Label.centerYAnchor),
            awayStat2Label.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -16),
            awayStat2Label.widthAnchor.constraint(equalToConstant: 80),
            
            awayStat3Label.centerYAnchor.constraint(equalTo: homeStat3Label.centerYAnchor),
            awayStat3Label.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -16),
            awayStat3Label.widthAnchor.constraint(equalToConstant: 80),
            
            awayStat4Label.centerYAnchor.constraint(equalTo: homeStat4Label.centerYAnchor),
            awayStat4Label.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -16),
            awayStat4Label.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    // MARK: - Action Methods
    @objc private func quarterChanged(_ sender: UISegmentedControl) {
        selectedQuarter = sender.titleForSegment(at: sender.selectedSegmentIndex) ?? "All"
        updateStats()
    }
    
    @objc private func viewTypeChanged(_ sender: UISwitch) {
        isQuarterView = sender.isOn
        viewTypeLabel.text = sender.isOn ? "Quarter View" : "Action View"
        updateStats()
    }
    
    @objc private func viewTypeLabelTapped() {
        viewTypeSwitch.setOn(!viewTypeSwitch.isOn, animated: true)
        viewTypeChanged(viewTypeSwitch)
    }
    
    @objc private func teamTypeChanged(_ sender: UISwitch) {
        isWholeTeam = sender.isOn
        teamTypeLabel.text = sender.isOn ? "Whole Team" : "Individual Players"
        
        // Clear selections when switching to whole team
        if isWholeTeam {
            selectedHomePlayerIndex = nil
            selectedAwayPlayerIndex = nil
            homeTeamTableView.reloadData()
            awayTeamTableView.reloadData()
        }
        
        updateStats()
    }
    
    @objc private func teamTypeLabelTapped() {
        teamTypeSwitch.setOn(!teamTypeSwitch.isOn, animated: true)
        teamTypeChanged(teamTypeSwitch)
    }
    
    // MARK: - Data Methods
    private func loadMatchData() {
        guard let match = match else { return }
        
        homeTeamTableLabel.text = match.home.name
        awayTeamTableLabel.text = match.away.name
        
        updateStats()
    }
    
    private func updateStats() {
        guard let match = match else { return }
        
        var homeActions = match.home.actions
        var awayActions = match.away.actions
        
        // Filter by quarter if needed
        if selectedQuarter != "All" {
            var quarter = Int(selectedQuarter.replacingOccurrences(of: "Q", with: "")) ?? 0
        if selectedQuarter == "Final" {
            quarter = 4
        }

            homeActions = homeActions.filter { $0.actionQuarter == quarter }
            awayActions = awayActions.filter { $0.actionQuarter == quarter }
        }
        
        // Filter by selected players if not whole team
        if !isWholeTeam {
            if let homeIndex = selectedHomePlayerIndex,
               let awayIndex = selectedAwayPlayerIndex {
                let homePlayer = match.home.players[homeIndex]
                let awayPlayer = match.away.players[awayIndex]
                
                homeActions = homeActions.filter { $0.positionNumber == homePlayer.positionNumber }
                awayActions = awayActions.filter { $0.positionNumber == awayPlayer.positionNumber }
            }
        }
        
        if isQuarterView {
            updateQuarterStats(homeActions: homeActions, awayActions: awayActions)
        } else {
            updateActionStats(homeActions: homeActions, awayActions: awayActions)
        }
    }
    
    private func updateQuarterStats(homeActions: [Match.Action], awayActions: [Match.Action]) {
        // Update labels
        stat1Label.text = "Q1"
        stat2Label.text = "Q2"
        stat3Label.text = "Q3"
        stat4Label.text = "Final"
        
        // Calculate scores for each quarter
        let homeQ1Goals = homeActions.filter { $0.action == "goal" && $0.actionQuarter == 1 }.count
        let homeQ1Behinds = homeActions.filter { $0.action == "behind" && $0.actionQuarter == 1 }.count
        let homeQ1Total = homeQ1Goals * 6 + homeQ1Behinds
        
        let awayQ1Goals = awayActions.filter { $0.action == "goal" && $0.actionQuarter == 1 }.count
        let awayQ1Behinds = awayActions.filter { $0.action == "behind" && $0.actionQuarter == 1 }.count
        let awayQ1Total = awayQ1Goals * 6 + awayQ1Behinds
        
        homeStat1Label.text = String(format: "%d . %d (%d)", homeQ1Goals, homeQ1Behinds, homeQ1Total)
        awayStat1Label.text = String(format: "%d . %d (%d)", awayQ1Goals, awayQ1Behinds, awayQ1Total)
        
        // Q2 (cumulative)
        let homeQ2Goals = homeActions.filter { $0.action == "goal" && $0.actionQuarter <= 2 }.count
        let homeQ2Behinds = homeActions.filter { $0.action == "behind" && $0.actionQuarter <= 2 }.count
        let homeQ2Total = homeQ2Goals * 6 + homeQ2Behinds
        
        let awayQ2Goals = awayActions.filter { $0.action == "goal" && $0.actionQuarter <= 2 }.count
        let awayQ2Behinds = awayActions.filter { $0.action == "behind" && $0.actionQuarter <= 2 }.count
        let awayQ2Total = awayQ2Goals * 6 + awayQ2Behinds
        
        homeStat2Label.text = String(format: "%d . %d (%d)", homeQ2Goals, homeQ2Behinds, homeQ2Total)
        awayStat2Label.text = String(format: "%d . %d (%d)", awayQ2Goals, awayQ2Behinds, awayQ2Total)
        
        // Q3 (cumulative)
        let homeQ3Goals = homeActions.filter { $0.action == "goal" && $0.actionQuarter <= 3 }.count
        let homeQ3Behinds = homeActions.filter { $0.action == "behind" && $0.actionQuarter <= 3 }.count
        let homeQ3Total = homeQ3Goals * 6 + homeQ3Behinds
        
        let awayQ3Goals = awayActions.filter { $0.action == "goal" && $0.actionQuarter <= 3 }.count
        let awayQ3Behinds = awayActions.filter { $0.action == "behind" && $0.actionQuarter <= 3 }.count
        let awayQ3Total = awayQ3Goals * 6 + awayQ3Behinds
        
        homeStat3Label.text = String(format: "%d . %d (%d)", homeQ3Goals, homeQ3Behinds, homeQ3Total)
        awayStat3Label.text = String(format: "%d . %d (%d)", awayQ3Goals, awayQ3Behinds, awayQ3Total)
        
        // Final (cumulative)
        let homeFinalGoals = homeActions.filter { $0.action == "goal" && $0.actionQuarter <= 4 }.count
        let homeFinalBehinds = homeActions.filter { $0.action == "behind" && $0.actionQuarter <= 4 }.count
        let homeFinalTotal = homeFinalGoals * 6 + homeFinalBehinds
        
        let awayFinalGoals = awayActions.filter { $0.action == "goal" && $0.actionQuarter <= 4 }.count
        let awayFinalBehinds = awayActions.filter { $0.action == "behind" && $0.actionQuarter <= 4 }.count
        let awayFinalTotal = awayFinalGoals * 6 + awayFinalBehinds
        
        homeStat4Label.text = String(format: "%d . %d (%d)", homeFinalGoals, homeFinalBehinds, homeFinalTotal)
        awayStat4Label.text = String(format: "%d . %d (%d)", awayFinalGoals, awayFinalBehinds, awayFinalTotal)
        
        // Update colors
        updateLabelColors()
    }
    
    private func updateActionStats(homeActions: [Match.Action], awayActions: [Match.Action]) {
        // Update labels
        stat1Label.text = "Disposals"
        stat2Label.text = "Marks"
        stat3Label.text = "Tackles"
        stat4Label.text = "Score"
        
        // Calculate stats
        let homeDisposals = homeActions.filter { $0.action == "kick" || $0.action == "hand" }.count
        let awayDisposals = awayActions.filter { $0.action == "kick" || $0.action == "hand" }.count
        
        let homeMarks = homeActions.filter { $0.action == "mark" }.count
        let awayMarks = awayActions.filter { $0.action == "mark" }.count
        
        let homeTackles = homeActions.filter { $0.action == "tackle" }.count
        let awayTackles = awayActions.filter { $0.action == "tackle" }.count
        
        let homeGoals = homeActions.filter { $0.action == "goal" }.count
        let homeBehinds = homeActions.filter { $0.action == "behind" }.count
        let homeTotal = homeGoals * 6 + homeBehinds
        
        let awayGoals = awayActions.filter { $0.action == "goal" }.count
        let awayBehinds = awayActions.filter { $0.action == "behind" }.count
        let awayTotal = awayGoals * 6 + awayBehinds
        
        // Update labels with right-aligned text
        homeStat1Label.text = String(format: "%d", homeDisposals)
        awayStat1Label.text = String(format: "%d", awayDisposals)
        
        homeStat2Label.text = String(format: "%d", homeMarks)
        awayStat2Label.text = String(format: "%d", awayMarks)
        
        homeStat3Label.text = String(format: "%d", homeTackles)
        awayStat3Label.text = String(format: "%d", awayTackles)
        
        homeStat4Label.text = String(format: "%d.%d (%d)", homeGoals, homeBehinds, homeTotal)
        awayStat4Label.text = String(format: "%d.%d (%d)", awayGoals, awayBehinds, awayTotal)
        
        // Set text alignment and width
        [homeStat1Label, homeStat2Label, homeStat3Label, homeStat4Label].forEach { 
            $0.textAlignment = .right
            $0.font = .monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        }
        [awayStat1Label, awayStat2Label, awayStat3Label, awayStat4Label].forEach { 
            $0.textAlignment = .left
            $0.font = .monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        }
        [stat1Label, stat2Label, stat3Label, stat4Label].forEach { 
            $0.textAlignment = .center
            $0.font = .systemFont(ofSize: 16, weight: .medium)
        }
        
        // Update colors
        updateLabelColors()
    }
    
    private func updateLabelColors() {
        // Helper function to update colors based on values
        func updateColor(homeLabel: UILabel, awayLabel: UILabel, homeValue: Int, awayValue: Int) {
            if homeValue > awayValue {
                homeLabel.textColor = .systemGreen
                awayLabel.textColor = .systemRed
            } else if homeValue < awayValue {
                homeLabel.textColor = .systemRed
                awayLabel.textColor = .systemGreen
            } else {
                homeLabel.textColor = .black
                awayLabel.textColor = .black
            }
        }
        
        if isQuarterView {
            // For quarter view, compare the total scores
            let homeQ1Total = Int(homeStat1Label.text?.components(separatedBy: "(").last?.replacingOccurrences(of: ")", with: "") ?? "0") ?? 0
            let awayQ1Total = Int(awayStat1Label.text?.components(separatedBy: "(").last?.replacingOccurrences(of: ")", with: "") ?? "0") ?? 0
            updateColor(homeLabel: homeStat1Label, awayLabel: awayStat1Label, homeValue: homeQ1Total, awayValue: awayQ1Total)
            
            let homeQ2Total = Int(homeStat2Label.text?.components(separatedBy: "(").last?.replacingOccurrences(of: ")", with: "") ?? "0") ?? 0
            let awayQ2Total = Int(awayStat2Label.text?.components(separatedBy: "(").last?.replacingOccurrences(of: ")", with: "") ?? "0") ?? 0
            updateColor(homeLabel: homeStat2Label, awayLabel: awayStat2Label, homeValue: homeQ2Total, awayValue: awayQ2Total)
            
            let homeQ3Total = Int(homeStat3Label.text?.components(separatedBy: "(").last?.replacingOccurrences(of: ")", with: "") ?? "0") ?? 0
            let awayQ3Total = Int(awayStat3Label.text?.components(separatedBy: "(").last?.replacingOccurrences(of: ")", with: "") ?? "0") ?? 0
            updateColor(homeLabel: homeStat3Label, awayLabel: awayStat3Label, homeValue: homeQ3Total, awayValue: awayQ3Total)
            
            let homeFinalTotal = Int(homeStat4Label.text?.components(separatedBy: "(").last?.replacingOccurrences(of: ")", with: "") ?? "0") ?? 0
            let awayFinalTotal = Int(awayStat4Label.text?.components(separatedBy: "(").last?.replacingOccurrences(of: ")", with: "") ?? "0") ?? 0
            updateColor(homeLabel: homeStat4Label, awayLabel: awayStat4Label, homeValue: homeFinalTotal, awayValue: awayFinalTotal)
        } else {
            // For action view, compare individual stats
            let homeDisposals = Int(homeStat1Label.text ?? "0") ?? 0
            let awayDisposals = Int(awayStat1Label.text ?? "0") ?? 0
            updateColor(homeLabel: homeStat1Label, awayLabel: awayStat1Label, homeValue: homeDisposals, awayValue: awayDisposals)
            
            let homeMarks = Int(homeStat2Label.text ?? "0") ?? 0
            let awayMarks = Int(awayStat2Label.text ?? "0") ?? 0
            updateColor(homeLabel: homeStat2Label, awayLabel: awayStat2Label, homeValue: homeMarks, awayValue: awayMarks)
            
            let homeTackles = Int(homeStat3Label.text ?? "0") ?? 0
            let awayTackles = Int(awayStat3Label.text ?? "0") ?? 0
            updateColor(homeLabel: homeStat3Label, awayLabel: awayStat3Label, homeValue: homeTackles, awayValue: awayTackles)
            
            let homeTotal = Int(homeStat4Label.text?.components(separatedBy: "(").last?.replacingOccurrences(of: ")", with: "") ?? "0") ?? 0
            let awayTotal = Int(awayStat4Label.text?.components(separatedBy: "(").last?.replacingOccurrences(of: ")", with: "") ?? "0") ?? 0
            updateColor(homeLabel: homeStat4Label, awayLabel: awayStat4Label, homeValue: homeTotal, awayValue: awayTotal)
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension StatsComparisonViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == homeTeamTableView {
            return match?.home.players.count ?? 0
        } else {
            return match?.away.players.count ?? 0
        }
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
                cell.backgroundColor = selectedHomePlayerIndex == indexPath.row ? .systemGreen.withAlphaComponent(0.2) : .white
                cell.selectionStyle = .default
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "AwayPlayerCell", for: indexPath)
            if let player = match?.away.players[indexPath.row] {
                var content = cell.defaultContentConfiguration()
                content.text = "\(player.playerName) (\(player.positionNumber))"
                if player.injuryStatus {
                    content.textProperties.color = .red
                }
                cell.contentConfiguration = content
                cell.backgroundColor = selectedAwayPlayerIndex == indexPath.row ? .systemGreen.withAlphaComponent(0.2) : .white
                cell.selectionStyle = .default
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == homeTeamTableView {
            // Deselect previous selection
            if let previousIndex = selectedHomePlayerIndex {
                let previousIndexPath = IndexPath(row: previousIndex, section: 0)
                tableView.deselectRow(at: previousIndexPath, animated: true)
            }
            
            selectedHomePlayerIndex = indexPath.row
            teamTypeSwitch.setOn(false, animated: true)
            teamTypeChanged(teamTypeSwitch)
            
            // If no away player is selected, select the first one
            if selectedAwayPlayerIndex == nil {
                selectedAwayPlayerIndex = 0
                awayTeamTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
            }
        } else {
            // Deselect previous selection
            if let previousIndex = selectedAwayPlayerIndex {
                let previousIndexPath = IndexPath(row: previousIndex, section: 0)
                tableView.deselectRow(at: previousIndexPath, animated: true)
            }
            
            selectedAwayPlayerIndex = indexPath.row
            teamTypeSwitch.setOn(false, animated: true)
            teamTypeChanged(teamTypeSwitch)
            
            // If no home player is selected, select the first one
            if selectedHomePlayerIndex == nil {
                selectedHomePlayerIndex = 0
                homeTeamTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
            }
        }
        
        // Update both table views to reflect selection
        homeTeamTableView.reloadData()
        awayTeamTableView.reloadData()
        
        // Update stats
        updateStats()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
} 
