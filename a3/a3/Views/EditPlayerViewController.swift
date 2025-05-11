import UIKit
import FirebaseFirestore
import PhotosUI

class EditPlayerViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playerImageView: UIImageView!
    @IBOutlet weak var playerNameTextField: UITextField!
    @IBOutlet weak var positionNumberTextField: UITextField!
    @IBOutlet weak var teamSegmentedControl: UISegmentedControl!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var match: Match?
    private var playerIndex: Int?
    private var team: String?
    private var selectedImage: UIImage?
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    private func setupUI() {
        title = "Edit Player"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
        
        cameraButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        // Setup image view
        playerImageView.contentMode = .scaleAspectFit
        playerImageView.layer.cornerRadius = 8
        playerImageView.clipsToBounds = true
        
        // Setup text fields
        playerNameTextField.placeholder = "Player Name"
        positionNumberTextField.placeholder = "Position Number"
        positionNumberTextField.keyboardType = .numberPad
        
        // Setup segmented control
        teamSegmentedControl.setTitle("Home", forSegmentAt: 0)
        teamSegmentedControl.setTitle("Away", forSegmentAt: 1)
    }
    
    private func loadData() {
        // Load match data from Firestore
        db.collection("matches").getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print("Error loading match data: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents,
                  let firstDocument = documents.first,
                  let match = Match(document: firstDocument) else {
                return
            }
            
            self?.match = match
            
            // If editing existing player
            if let playerIndex = self?.playerIndex,
               let team = self?.team {
                self?.titleLabel.text = "EDIT PLAYER"
                self?.teamSegmentedControl.isEnabled = false
                
                let player: Player
                if team == "HOME" {
                    player = match.home.players[playerIndex]
                    self?.teamSegmentedControl.selectedSegmentIndex = 0
                } else {
                    player = match.away.players[playerIndex]
                    self?.teamSegmentedControl.selectedSegmentIndex = 1
                }
                
                self?.playerNameTextField.text = player.playerName
                self?.positionNumberTextField.text = String(player.positionNumber)
                
                if !player.image.isEmpty {
                    if let imageData = Data(base64Encoded: player.image),
                       let image = UIImage(data: imageData) {
                        self?.playerImageView.image = image
                        self?.selectedImage = image
                    }
                }
            } else {
                self?.titleLabel.text = "ADD PLAYER"
                self?.teamSegmentedControl.isEnabled = true
                self?.teamSegmentedControl.selectedSegmentIndex = 0
            }
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func cameraButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.checkCameraPermission()
        }
        
        let libraryAction = UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.showImagePicker()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(cameraAction)
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
            showCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.showCamera()
                    }
                }
            }
        default:
            showPermissionAlert()
        }
    }
    
    private func showCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    private func showImagePicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
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
    
    @objc private func saveButtonTapped() {
        guard let match = match,
              let playerName = playerNameTextField.text,
              let positionText = positionNumberTextField.text,
              let positionNumber = Int(positionText) else {
            return
        }
        
        // Validate input
        if playerName.isEmpty {
            showAlert(message: "Please enter player name")
            return
        }
        
        if positionNumber < 0 {
            showAlert(message: "Please enter a valid position number")
            return
        }
        
        // Check if position number already exists
        let isHomeTeam = teamSegmentedControl.selectedSegmentIndex == 0
        let players = isHomeTeam ? match.home.players : match.away.players
        
        if let playerIndex = playerIndex {
            // Editing existing player
            if players.contains(where: { $0.positionNumber == positionNumber && $0.playerName != players[playerIndex].playerName }) {
                showAlert(message: "This position number already exists in the team")
                return
            }
        } else {
            // Adding new player
            if players.contains(where: { $0.positionNumber == positionNumber }) {
                showAlert(message: "This position number already exists in the team")
                return
            }
        }
        
        // Convert image to base64
        let imageBase64 = selectedImage?.jpegData(compressionQuality: 0.5)?.base64EncodedString() ?? ""
        
        let newPlayer = Player(
            playerName: playerName,
            positionNumber: positionNumber,
            image: imageBase64
        )
        
        // Update Firestore
        if let playerIndex = playerIndex {
            // Update existing player
            var players = isHomeTeam ? match.home.players : match.away.players
            players[playerIndex] = newPlayer
            
            db.collection("matches").document(match.id!).updateData([
                isHomeTeam ? "home.players" : "away.players": players.map { $0.dictionary }
            ]) { [weak self] error in
                if let error = error {
                    print("Error updating player: \(error)")
                    return
                }
                self?.navigationController?.popViewController(animated: true)
            }
        } else {
            // Add new player
            var players = isHomeTeam ? match.home.players : match.away.players
            players.append(newPlayer)
            
            db.collection("matches").document(match.id!).updateData([
                isHomeTeam ? "home.players" : "away.players": players.map { $0.dictionary }
            ]) { [weak self] error in
                if let error = error {
                    print("Error adding player: \(error)")
                    return
                }
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
        if let image = info[.originalImage] as? UIImage {
            playerImageView.image = image
            selectedImage = image
        }
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
                    DispatchQueue.main.async {
                        self?.playerImageView.image = image
                        self?.selectedImage = image
                    }
                }
            }
        }
    }
} 
