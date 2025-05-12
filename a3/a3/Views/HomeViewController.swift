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
        setupBurgerMenu()
    }
    
    private func setupBurgerMenu() {
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal"), style: .plain, target: self, action: #selector(showMenu))
        navigationItem.leftBarButtonItem = menuButton
    }
    
    @objc private func showMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
//        let teamManagementAction = UIAlertAction(title: "Team Management", style: .default) { [weak self] _ in
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            let teamManagementVC = storyboard.instantiateViewController(withIdentifier: "TeamManagementViewController") as! TeamManagementViewController
//            self?.navigationController?.pushViewController(teamManagementVC, animated: true)
//        }
        
        let historyAction = UIAlertAction(title: "History", style: .default) { [weak self] _ in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let historyVC = storyboard.instantiateViewController(withIdentifier: "HistoryViewController") as! HistoryViewController
            self?.navigationController?.pushViewController(historyVC, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
//        alertController.addAction(teamManagementAction)
        alertController.addAction(historyAction)
        alertController.addAction(cancelAction)
        
        // For iPad support
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.leftBarButtonItem
        }
        
        present(alertController, animated: true)
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
