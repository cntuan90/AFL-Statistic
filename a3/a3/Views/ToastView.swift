import UIKit

class ToastView: UIView {
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(message: String, type: ToastType = .success) {
        super.init(frame: .zero)
        setupUI(message: message, type: type)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(message: String, type: ToastType) {
        backgroundColor = type.backgroundColor
        layer.cornerRadius = 8
        alpha = 0
        
        addSubview(messageLabel)
        messageLabel.text = message
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    enum ToastType {
        case success
        case error
        case warning
        
        var backgroundColor: UIColor {
            switch self {
            case .success:
                return UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.9)
            case .error:
                return UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 0.9)
            case .warning:
                return UIColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 0.9)
            }
        }
    }
}

extension UIViewController {
    func showToast(message: String, type: ToastView.ToastType = .success, duration: TimeInterval = 2.0) {
        let toast = ToastView(message: message, type: type)
        
        // Get the window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(toast)
            
            toast.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                toast.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 16),
                toast.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -16),
                toast.widthAnchor.constraint(lessThanOrEqualTo: window.widthAnchor, multiplier: 0.7)
            ])
            
            UIView.animate(withDuration: 0.3, animations: {
                toast.alpha = 1
            }) { _ in
                UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                    toast.alpha = 0
                }) { _ in
                    toast.removeFromSuperview()
                }
            }
        }
    }
} 