import UIKit
import FirebaseFirestore

class HomeViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addMatchButton: UIBarButtonItem!
    @IBOutlet weak var historyButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    private var matches: [Match] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupFirestoreListener()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MatchCell")
    }
    
    private func setupFirestoreListener() {
        listener = db.collection("matches")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening to Firestore updates: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                self?.matches = documents.compactMap { document in
                    Match(document: document)
                }
                self?.tableView.reloadData()
            }
    }
    
    @IBAction func addMatchButtonTapped(_ sender: UIBarButtonItem) {
        let addMatchVC = AddMatchViewController()
        addMatchVC.modalPresentationStyle = .fullScreen
        present(addMatchVC, animated: true)
    }
    
    
    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        guard let match = matches.first else { return }
        let csvData = generateCSVData(for: match)
        let activityVC = UIActivityViewController(activityItems: [csvData], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    private func generateCSVData(for match: Match) -> String {
        var csvBuilder = "Action,Action Team,Time,Player Name,Position Number,Action Quarter\n"
        match.home.actions.forEach { action in
            csvBuilder += "\(action.action),\(action.actionTeam),\(action.time),\(action.playerName),\(action.positionNumber),\(action.actionQuarter)\n"
        }
        match.away.actions.forEach { action in
            csvBuilder += "\(action.action),\(action.actionTeam),\(action.time),\(action.playerName),\(action.positionNumber),\(action.actionQuarter)\n"
        }
        return csvBuilder
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchCell", for: indexPath)
        let match = matches[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = "\(match.home.name) vs \(match.away.name)"
        content.secondaryText = match.status
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let match = matches[indexPath.row]
    }
}
