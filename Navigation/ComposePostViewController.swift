import UIKit
import PhotosUI
import FirebaseAuth

/// Полноценный экран создания поста — текст + фото из галереи (PHPickerViewController).
/// Раньше единственным способом добавить пост был drag&drop на iPad; это обычный,
/// ожидаемый способ, доступный на любом устройстве.
final class ComposePostViewController: UIViewController {
    
    var onPostCreated: (() -> Void)?
    
    private let postsService: PostsServiceProtocol
    private var selectedImage: UIImage?
    
    init(postsService: PostsServiceProtocol = AppDependencyContainer.shared.postsService) {
        self.postsService = postsService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = AppFonts.body
        tv.textColor = AppColors.primaryText
        tv.backgroundColor = AppColors.secondaryBackground
        tv.layer.cornerRadius = 10
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "compose.placeholder".localized
        label.font = AppFonts.body
        label.textColor = AppColors.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let imagePreview: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = AppColors.secondaryBackground
        iv.layer.cornerRadius = 10
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private lazy var pickPhotoButton = CustomButton(title: "compose.pick_photo".localized) { [weak self] in
        self?.presentPhotoPicker()
    }
    
    private lazy var postButton = CustomButton(title: "compose.post".localized) { [weak self] in
        self?.submitPost()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "compose.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        textView.delegate = self
        setupLayout()
    }
    
    private func setupLayout() {
        [textView, placeholderLabel, imagePreview, pickPhotoButton, postButton].forEach {
            view.addSubview($0)
        }
        
        let contentGroup = UIView()
        contentGroup.translatesAutoresizingMaskIntoConstraints = false
        // Оборачиваем в контейнер только ради адаптивной ширины на iPad — сам контейнер
        // растягивается через pinAdaptiveWidth, а элементы внутри крепятся к нему
        view.addSubview(contentGroup)
        contentGroup.pinAdaptiveWidth(in: view, maxWidth: 600)
        
        [textView, placeholderLabel, imagePreview, pickPhotoButton, postButton].forEach {
            $0.removeFromSuperview()
            contentGroup.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            contentGroup.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            
            textView.topAnchor.constraint(equalTo: contentGroup.topAnchor),
            textView.leadingAnchor.constraint(equalTo: contentGroup.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: contentGroup.trailingAnchor),
            textView.heightAnchor.constraint(equalToConstant: 120),
            
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 16),
            
            imagePreview.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            imagePreview.leadingAnchor.constraint(equalTo: contentGroup.leadingAnchor),
            imagePreview.trailingAnchor.constraint(equalTo: contentGroup.trailingAnchor),
            imagePreview.heightAnchor.constraint(equalToConstant: 200),
            
            pickPhotoButton.topAnchor.constraint(equalTo: imagePreview.bottomAnchor, constant: 16),
            pickPhotoButton.leadingAnchor.constraint(equalTo: contentGroup.leadingAnchor),
            pickPhotoButton.trailingAnchor.constraint(equalTo: contentGroup.trailingAnchor),
            pickPhotoButton.heightAnchor.constraint(equalToConstant: 50),
            
            postButton.topAnchor.constraint(equalTo: pickPhotoButton.bottomAnchor, constant: 16),
            postButton.leadingAnchor.constraint(equalTo: contentGroup.leadingAnchor),
            postButton.trailingAnchor.constraint(equalTo: contentGroup.trailingAnchor),
            postButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func submitPost() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            showAlert(message: "compose.error.empty_text".localized)
            return
        }
        
        let author = Auth.auth().currentUser?.email ?? "compose.default_author".localized
        postButton.isEnabled = false
        
        postsService.addPost(author: author, description: text, image: selectedImage) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.postButton.isEnabled = true
                
                switch result {
                case .success:
                    self.onPostCreated?()
                    self.dismiss(animated: true)
                case .failure(let error):
                    self.showAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "common.error".localized, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
        present(alert, animated: true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

extension ComposePostViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

extension ComposePostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                guard let self = self, let image = object as? UIImage else { return }
                self.selectedImage = image
                self.imagePreview.image = image
                self.imagePreview.isHidden = false
            }
        }
    }
}
