import UIKit
import FirebaseFirestore


class HomeViewController: UIViewController {
    var matches: [Match] = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addMatchButton: UIBarButtonItem!
    @IBOutlet weak var historyButton: UIBarButtonItem!
    
//    var matches: [Match] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupFirestoreListener()
        
        // Add history button
        let historyButton = UIBarButtonItem(image: UIImage(systemName: "clock.arrow.circlepath"), style: .plain, target: self, action: #selector(historyButtonTapped))
        navigationItem.leftBarButtonItem = historyButton
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MatchCell")
    }
    
    private func setupFirestoreListener() {
        print("Setting up Firestore listener...")
        listener = db.collection("matches")
            .whereField("status", isNotEqualTo: "Ended")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening to Firestore updates: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                print("Found \(documents.count) documents")
                
                self?.matches = documents.compactMap { document in
                    print("Processing document: \(document.documentID)")
                    if let match = Match(document: document) {
                        print("Home team players: \(match.home.players.count)")
                        print("Away team players: \(match.away.players.count)")
                        return match
                    }
                    return nil
                }
                
                print("Successfully loaded \(self?.matches.count ?? 0) matches")
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
    }
    
    @IBAction func addMatchButtonTapped(_ sender: UIBarButtonItem) {
        let addMatchVC = AddMatchViewController()
        addMatchVC.modalPresentationStyle = .fullScreen
        present(addMatchVC, animated: true)
    }
    
    // MARK: - Actions
    @objc private func historyButtonTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let historyVC = storyboard.instantiateViewController(withIdentifier: "HistoryViewController") as? HistoryViewController {
            navigationController?.pushViewController(historyVC, animated: true)
        }
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
        content.secondaryText = "\(match.status) - \(match.date)"
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let match = matches[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let recordActionVC = storyboard.instantiateViewController(withIdentifier: "RecordActionViewController") as! RecordActionViewController
        
        print("Loading Home:")
        print("Home: \(match.home.players.count)")
        print("Away: \(match.away.players.count)")
        recordActionVC.match = match
        navigationController?.pushViewController(recordActionVC, animated: true)
    }
}
