import UIKit
import FirebaseFirestore

class TeamManagementViewController: UIViewController {
    @IBOutlet weak var homeTeamLabel: UILabel!
    @IBOutlet weak var awayTeamLabel: UILabel!
    @IBOutlet weak var homeTeamTableView: UITableView!
    @IBOutlet weak var awayTeamTableView: UITableView!
    @IBOutlet weak var homeTeamSearchBar: UISearchBar!
    @IBOutlet weak var awayTeamSearchBar: UISearchBar!
    @IBOutlet weak var addPlayerButton: UIBarButtonItem!
    
    private var homeTeamPlayers: [Player] = []
    private var awayTeamPlayers: [Player] = []
    private var filteredHomePlayers: [Player] = []
    private var filteredAwayPlayers: [Player] = []
    var match: Match?
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupSearchBars()
        loadMatchData()
    }
    
    private func setupUI() {
        title = "Team Management"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
    }
    
    private func setupTableView() {
        homeTeamTableView.delegate = self
        homeTeamTableView.dataSource = self
        awayTeamTableView.delegate = self
        awayTeamTableView.dataSource = self
        
        homeTeamTableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlayerCell")
        awayTeamTableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlayerCell")
    }
    
    private func setupSearchBars() {
        homeTeamSearchBar.delegate = self
        awayTeamSearchBar.delegate = self
    }
    
    private func loadMatchData() {
        guard let match = match else { return }
        
        self.homeTeamLabel.text = match.home.name
        self.awayTeamLabel.text = match.away.name
        self.homeTeamPlayers = match.home.players
        self.awayTeamPlayers = match.away.players
        self.filteredHomePlayers = match.home.players
        self.filteredAwayPlayers = match.away.players
        
        DispatchQueue.main.async {
            self.homeTeamTableView.reloadData()
            self.awayTeamTableView.reloadData()
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func addPlayerButtonTapped(_ sender: UIBarButtonItem) {
        guard let match = match else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let editPlayerVC = storyboard.instantiateViewController(withIdentifier: "EditPlayerViewController") as! EditPlayerViewController
        editPlayerVC.match = match
        navigationController?.pushViewController(editPlayerVC, animated: true)
    }
}

extension TeamManagementViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == homeTeamTableView {
            return filteredHomePlayers.count
        } else {
            return filteredAwayPlayers.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath)
        let player: Player
        
        if tableView == homeTeamTableView {
            player = filteredHomePlayers[indexPath.row]
        } else {
            player = filteredAwayPlayers[indexPath.row]
        }
        
        var content = cell.defaultContentConfiguration()
        content.text = "\(player.playerName) (\(player.positionNumber))"
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let match = match else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let editPlayerVC = storyboard.instantiateViewController(withIdentifier: "EditPlayerViewController") as! EditPlayerViewController
        
        let selectedPlayer: Player
        if tableView == homeTeamTableView {
            selectedPlayer = filteredHomePlayers[indexPath.row]
        } else {
            selectedPlayer = filteredAwayPlayers[indexPath.row]
        }
        
        editPlayerVC.match = match
        editPlayerVC.player = selectedPlayer
        editPlayerVC.isEditMode = true
        navigationController?.pushViewController(editPlayerVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let player: Player
            let isHomeTeam = tableView == homeTeamTableView
            
            if isHomeTeam {
                player = filteredHomePlayers[indexPath.row]
            } else {
                player = filteredAwayPlayers[indexPath.row]
            }
            
            // Show confirmation alert
            let alertController = UIAlertController(title: "Delete Player", message: "Are you sure you want to delete \(player.playerName)?", preferredStyle: .alert)
            
            let deleteAction = UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
                guard let match = self?.match else { return }
                
                // Remove from Firestore
                self?.db.collection("matches").document(match.id!).updateData([
                    isHomeTeam ? "home.players" : "away.players": FieldValue.arrayRemove([player.dictionary])
                ]) { error in
                    if let error = error {
                        print("Error deleting player: \(error)")
                        return
                    }
                    
                    // Update local data
                    if isHomeTeam {
                        self?.homeTeamPlayers.removeAll { $0.playerName == player.playerName }
                        self?.filteredHomePlayers.removeAll { $0.playerName == player.playerName }
                    } else {
                        self?.awayTeamPlayers.removeAll { $0.playerName == player.playerName }
                        self?.filteredAwayPlayers.removeAll { $0.playerName == player.playerName }
                    }
                    
                    DispatchQueue.main.async {
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                }
            }
            
            let cancelAction = UIAlertAction(title: "No", style: .cancel)
            
            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true)
        }
    }
}

extension TeamManagementViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar == homeTeamSearchBar {
            filteredHomePlayers = searchText.isEmpty ? homeTeamPlayers : homeTeamPlayers.filter { $0.playerName.lowercased().contains(searchText.lowercased()) }
            homeTeamTableView.reloadData()
        } else {
            filteredAwayPlayers = searchText.isEmpty ? awayTeamPlayers : awayTeamPlayers.filter { $0.playerName.lowercased().contains(searchText.lowercased()) }
            awayTeamTableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
