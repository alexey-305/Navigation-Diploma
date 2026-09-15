import UIKit

/// Полноэкранный просмотр истории — картинка на весь экран, сверху анимированная
/// полоса прогресса (как в VK/Instagram), автоматически закрывается через 4 секунды,
/// либо по тапу.
final class StoryViewerViewController: UIViewController {
    
    private let story: StoriesBarView.Story
    private let duration: TimeInterval = 4
    
    init(story: StoriesBarView.Story) {
        self.story = story
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let progressTrack: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let progressFill: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var progressWidthConstraint: NSLayoutConstraint?
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.headline
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        imageView.image = story.image
        authorLabel.text = story.author
        
        setupLayout()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.layoutIfNeeded()
        
        progressWidthConstraint?.constant = 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) {
            self.progressWidthConstraint?.constant = self.progressTrack.bounds.width
            self.view.layoutIfNeeded()
        } completion: { [weak self] finished in
            if finished {
                self?.dismiss(animated: true)
            }
        }
    }
    
    private func setupLayout() {
        [imageView, progressTrack, authorLabel].forEach { view.addSubview($0) }
        progressTrack.addSubview(progressFill)
        
        let widthConstraint = progressFill.widthAnchor.constraint(equalToConstant: 0)
        progressWidthConstraint = widthConstraint
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            progressTrack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            progressTrack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            progressTrack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            progressTrack.heightAnchor.constraint(equalToConstant: 4),
            
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            widthConstraint,
            
            authorLabel.topAnchor.constraint(equalTo: progressTrack.bottomAnchor, constant: 12),
            authorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }
    
    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
}
