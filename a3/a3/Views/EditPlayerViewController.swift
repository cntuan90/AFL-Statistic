import UIKit
import FirebaseFirestore
import PhotosUI
import AVFoundation

class EditPlayerViewController: UIViewController {
//    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playerImageView: UIImageView!
    @IBOutlet weak var playerNameTextField: UITextField!
    @IBOutlet weak var positionNumberTextField: UITextField!
    @IBOutlet weak var teamSegmentedControl: UISegmentedControl!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var match: Match?
    var player: Player?
    var isEditMode: Bool = false
    private var playerIndex: Int?
    private var team: String?
    private var selectedImage: UIImage?
    private let db = Firestore.firestore()
    private let imagePicker = UIImagePickerController()
    var onPlayerUpdated: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    private func setupUI() {
        title = "Edit Player"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
        
        cameraButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped(_:)), for: .touchUpInside)
        
        // Setup image view
        playerImageView.contentMode = .scaleAspectFit
        playerImageView.layer.cornerRadius = 8
        playerImageView.clipsToBounds = true
        
        // Setup text fields
        playerNameTextField.placeholder = "Player Name"
        positionNumberTextField.placeholder = "Position Number"
        positionNumberTextField.keyboardType = .numberPad
        
        // Setup segmented control with team names
        if let match = match {
            teamSegmentedControl.setTitle(match.home.name, forSegmentAt: 0)
            teamSegmentedControl.setTitle(match.away.name, forSegmentAt: 1)
        } else {
            teamSegmentedControl.setTitle("Home", forSegmentAt: 0)
            teamSegmentedControl.setTitle("Away", forSegmentAt: 1)
        }
    }
    
    private func loadData() {
        if isEditMode, let player = player {
//            titleLabel.text = "EDIT PLAYER"
            title = "Edit Player"
            playerNameTextField.text = player.playerName
            positionNumberTextField.text = String(player.positionNumber)
            teamSegmentedControl.isEnabled = false
            
            // Set team segment based on which team the player belongs to
            if let match = match {
                // Update team names in segmented control
                teamSegmentedControl.setTitle(match.home.name, forSegmentAt: 0)
                teamSegmentedControl.setTitle(match.away.name, forSegmentAt: 1)
                
                if match.home.players.contains(where: { $0.playerName == player.playerName }) {
                    teamSegmentedControl.selectedSegmentIndex = 0
                } else {
                    teamSegmentedControl.selectedSegmentIndex = 1
                }
            }
            
            // Load player image if exists
            if !player.image.isEmpty {
                if let imageData = Data(base64Encoded: player.image),
                   let image = UIImage(data: imageData) {
                    playerImageView.image = image
                    selectedImage = image
                }
            }
        } else {
//            titleLabel.text = "ADD PLAYER"
            title = "Add Player"
            teamSegmentedControl.isEnabled = true
            teamSegmentedControl.selectedSegmentIndex = 0
            
            // Update team names in segmented control for new player
            if let match = match {
                teamSegmentedControl.setTitle(match.home.name, forSegmentAt: 0)
                teamSegmentedControl.setTitle(match.away.name, forSegmentAt: 1)
            }
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cameraButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
//        let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
//            self?.checkCameraPermission()
//        }
        
        let libraryAction = UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.showImagePicker()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
//        alertController.addAction(cameraAction)
        alertController.addAction(libraryAction)
        alertController.addAction(cancelAction)
        
        // For iPad support
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = cameraButton
            popoverController.sourceRect = cameraButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.showCamera()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.showCamera()
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.showPermissionAlert()
            }
        @unknown default:
            break
        }
    }
    
    private func showCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            present(imagePicker, animated: true)
        } else {
            showAlert(message: "Camera is not available on this device")
        }
    }
    
    private func showImagePicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please allow camera access in Settings to take photos.",
            preferredStyle: .alert
        )
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func updateMatchData(completion: @escaping () -> Void) {
        guard let match = match, let matchId = match.id else {
            completion()
            return
        }
        
        db.collection("matches").document(matchId).getDocument { [weak self] (document, error) in
            guard let self = self,
                  let document = document,
                  let data = document.data(),
                  let homeData = data["home"] as? [String: Any],
                  let awayData = data["away"] as? [String: Any],
                  let homePlayersData = homeData["players"] as? [[String: Any]],
                  let awayPlayersData = awayData["players"] as? [[String: Any]] else {
                completion()
                return
            }
            
            // Convert Firestore data to Player objects
            let homePlayers = homePlayersData.compactMap { playerData -> Player? in
                guard let playerName = playerData["playerName"] as? String,
                      let positionNumber = playerData["positionNumber"] as? Int else {
                    return nil
                }
                return Player(
                    playerName: playerName,
                    positionNumber: positionNumber,
                    image: playerData["image"] as? String ?? "",
                    injuryStatus: playerData["injuryStatus"] as? Bool ?? false
                )
            }
            
            let awayPlayers = awayPlayersData.compactMap { playerData -> Player? in
                guard let playerName = playerData["playerName"] as? String,
                      let positionNumber = playerData["positionNumber"] as? Int else {
                    return nil
                }
                return Player(
                    playerName: playerName,
                    positionNumber: positionNumber,
                    image: playerData["image"] as? String ?? "",
                    injuryStatus: playerData["injuryStatus"] as? Bool ?? false
                )
            }
            
            // Update match data
            self.match?.home.players = homePlayers
            self.match?.away.players = awayPlayers
            
            completion()
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let match = match else { return }
        
        let playerName = playerNameTextField.text ?? ""
        let positionText = positionNumberTextField.text ?? ""
        let positionNumber = Int(positionText) ?? -1
        let isHomeTeam = teamSegmentedControl.selectedSegmentIndex == 0
        
        // Convert image to base64
        let imageBase64: String
        if let image = selectedImage,
           let imageData = image.jpegData(compressionQuality: 0.5) {
            imageBase64 = imageData.base64EncodedString()
        } else {
            imageBase64 = ""
        }
        
        // Check if position number already exists in the team
        let positionNumberExists: Bool
        if isHomeTeam {
            positionNumberExists = match.home.players.contains { player in
                if isEditMode, let currentPlayer = self.player {
                    return player.positionNumber == positionNumber && player.playerName != currentPlayer.playerName
                } else {
                    return player.positionNumber == positionNumber
                }
            }
        } else {
            positionNumberExists = match.away.players.contains { player in
                if isEditMode, let currentPlayer = self.player {
                    return player.positionNumber == positionNumber && player.playerName != currentPlayer.playerName
                } else {
                    return player.positionNumber == positionNumber
                }
            }
        }
        
        // Validate input
        if playerName.isEmpty {
            showToast(message: "Please enter player name", type: .warning)
            return
        }
        
        if positionNumber < 0 {
            showToast(message: "Please enter a valid position number", type: .warning)
            return
        }
        
        if positionNumberExists {
            showToast(message: "This position number already exists in the team", type: .warning)
            return
        }
        
        let newPlayer = Player(
            playerName: playerName,
            positionNumber: positionNumber,
            image: imageBase64
        )
        
        // Update Firestore
        if isEditMode {
            // Update existing player
            var players = isHomeTeam ? match.home.players : match.away.players
            if let index = players.firstIndex(where: { $0.playerName == player?.playerName }) {
                players[index] = newPlayer
                
                let fieldPath = isHomeTeam ? "home.players" : "away.players"
                db.collection("matches").document(match.id!).updateData([
                    fieldPath: players.map { $0.dictionary }
                ]) { [weak self] error in
                    if let error = error {
                        print("Error updating player: \(error)")
                        self?.showToast(message: "Error updating player: \(error.localizedDescription)", type: .error)
                        return
                    }
                    
                    // Update the match object with the new player data
                    if isHomeTeam {
                        self?.match?.home.players = players
                    } else {
                        self?.match?.away.players = players
                    }
                    
                    // Notify parent and pop view controller
                    self?.onPlayerUpdated?()
                    self?.showToast(message: "Player updated successfully", type: .success)
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        } else {
            // Add new player
            var players = isHomeTeam ? match.home.players : match.away.players
            players.append(newPlayer)
            
            let fieldPath = isHomeTeam ? "home.players" : "away.players"
            db.collection("matches").document(match.id!).updateData([
                fieldPath: players.map { $0.dictionary }
            ]) { [weak self] error in
                if let error = error {
                    print("Error adding player: \(error)")
                    self?.showToast(message: "Error adding player: \(error.localizedDescription)", type: .error)
                    return
                }
                
                // Update the match object with the new player data
                if isHomeTeam {
                    self?.match?.home.players = players
                } else {
                    self?.match?.away.players = players
                }
                
                // Notify parent and pop view controller
                self?.onPlayerUpdated?()
                self?.showToast(message: "Player added successfully", type: .success)
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension EditPlayerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            // Resize image if needed
            let maxSize: CGFloat = 1024
            let scale = min(maxSize / image.size.width, maxSize / image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let resizedImage = resizedImage {
                playerImageView.image = resizedImage
                selectedImage = resizedImage
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension EditPlayerViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider else { return }
        
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                if let image = image as? UIImage {
                    // Resize image if needed
                    let maxSize: CGFloat = 1024
                    let scale = min(maxSize / image.size.width, maxSize / image.size.height)
                    let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                    
                    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                    image.draw(in: CGRect(origin: .zero, size: newSize))
                    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    DispatchQueue.main.async {
                        if let resizedImage = resizedImage {
                            self?.playerImageView.image = resizedImage
                            self?.selectedImage = resizedImage
                        }
                    }
                }
            }
        }
    }
} 
