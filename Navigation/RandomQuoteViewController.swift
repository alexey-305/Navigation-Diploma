import UIKit

class RandomQuoteViewController: UIViewController {
    
    private let viewModel: RandomQuoteViewModel
    
    init(viewModel: RandomQuoteViewModel = AppDependencyContainer.shared.makeRandomQuoteViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let quoteLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = AppFonts.body
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "random_quote.hint".localized
        return label
    }()
    
    private let offlineLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = AppFonts.caption
        label.textColor = .systemOrange
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let loadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("random_quote.button.load".localized, for: .normal)
        button.backgroundColor = AppColors.accent
        button.setTitleColor(AppColors.onAccentText, for: .normal)
        button.titleLabel?.font = AppFonts.button
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "random_quote.title".localized
        setupUI()
        bindViewModel()
        loadButton.addTarget(self, action: #selector(loadQuote), for: .touchUpInside)
    }
    
    private func setupUI() {
        view.addSubview(quoteLabel)
        view.addSubview(offlineLabel)
        view.addSubview(loadButton)
        
        quoteLabel.pinAdaptiveWidth(in: view, maxWidth: 600)
        offlineLabel.pinAdaptiveWidth(in: view, maxWidth: 600)
        
        NSLayoutConstraint.activate([
            quoteLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            
            offlineLabel.topAnchor.constraint(equalTo: quoteLabel.bottomAnchor, constant: 8),
            
            loadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadButton.topAnchor.constraint(equalTo: offlineLabel.bottomAnchor, constant: 22),
            loadButton.widthAnchor.constraint(equalToConstant: 200),
            loadButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] state in
            self?.handle(state: state)
        }
    }
    
    private func handle(state: RandomQuoteViewState) {
        switch state {
        case .idle:
            break
        case .loading:
            loadButton.isEnabled = false
            loadButton.setTitle("random_quote.button.loading".localized, for: .normal)
            offlineLabel.isHidden = true
        case .loaded(let text):
            loadButton.isEnabled = true
            loadButton.setTitle("random_quote.button.load".localized, for: .normal)
            offlineLabel.isHidden = true
            quoteLabel.text = text
        case .loadedFromCache(let text):
            loadButton.isEnabled = true
            loadButton.setTitle("random_quote.button.load".localized, for: .normal)
            offlineLabel.isHidden = false
            offlineLabel.text = "random_quote.offline_cache".localized
            quoteLabel.text = text
        case .failed(let message):
            loadButton.isEnabled = true
            loadButton.setTitle("random_quote.button.load".localized, for: .normal)
            offlineLabel.isHidden = true
            quoteLabel.text = message
        }
    }
    
    @objc private func loadQuote() {
        viewModel.loadRandomQuote()
    }
}
