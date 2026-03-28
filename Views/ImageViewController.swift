import UIKit

class ImageViewController: UIViewController {
    // MARK: - Properties
    private var base64String: String?
    
    // MARK: - UI Elements
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Player Image"
        
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(with base64String: String) {
        self.base64String = base64String
    }
    
    // MARK: - Helper Methods
    private func loadImage() {
        guard let base64String = base64String,
              let imageData = Data(base64Encoded: base64String),
              let image = UIImage(data: imageData) else {
            // Show error image or message if image loading fails
            imageView.image = UIImage(systemName: "person.fill")
            imageView.tintColor = .gray
            return
        }
        
        imageView.image = image
    }
} 