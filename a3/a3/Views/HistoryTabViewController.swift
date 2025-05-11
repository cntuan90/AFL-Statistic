import UIKit
import FirebaseFirestore

class HistoryTabViewController: UIViewController {
    
    // MARK: - Properties
    private var completedMatches: [Match] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MatchCell")
        return tableView
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupFirestoreListener()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        title = "Match History"
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupFirestoreListener() {
        listener = db.collection("matches")
            .whereField("status", isEqualTo: "Completed")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening to Firestore updates: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                self?.completedMatches = documents.compactMap { document in
                    return Match(document: document)
                }
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension HistoryTabViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return completedMatches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchCell", for: indexPath)
        let match = completedMatches[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = "\(match.home.name) vs \(match.away.name)"
        content.secondaryText = "\(match.status) - \(match.date)"
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let match = completedMatches[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let recordActionVC = storyboard.instantiateViewController(withIdentifier: "RecordActionViewController") as! RecordActionViewController
        recordActionVC.match = match
        navigationController?.pushViewController(recordActionVC, animated: true)
    }
} 
