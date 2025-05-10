import UIKit
import FirebaseFirestore

class HistoryTabViewController: UIViewController {
    // MARK: - Properties
    private var matches: [Match] = []
    private let db = Firestore.firestore()
    
    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MatchCell")
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
        view.backgroundColor = .white
        title = "Match History"
        
        view.addSubview(tableView)
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
    private func loadMatches() {
        db.collection("matches")
            .whereField("status", isEqualTo: "Completed")
            .order(by: "date", descending: true)
            .getDocuments { [weak self] (snapshot, error) in
                if let error = error {
                    print("Error loading matches: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.matches = documents.compactMap { Match(document: $0) }
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension HistoryTabViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchCell", for: indexPath)
        
        let match = matches[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = "\(match.home.name) vs \(match.away.name)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        content.secondaryText = match.date
        
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let match = matches[indexPath.row]
        let summaryVC = SummaryViewController()
        summaryVC.match = match
        navigationController?.pushViewController(summaryVC, animated: true)
    }
} 
