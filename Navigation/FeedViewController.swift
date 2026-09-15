import UIKit
import CoreData

class FeedViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: FeedViewModel
    
    init(viewModel: FeedViewModel = AppDependencyContainer.shared.makeFeedViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Elements
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        // Не регистрируем UITableViewCell.self — используем .subtitle через dequeue вручную
        return tv
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let storiesBarView: StoriesBarView = {
        let view = StoriesBarView(frame: CGRect(x: 0, y: 0, width: 0, height: 108))
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "feed.title".localized
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(composeButtonTapped)
        )
        
        setupTableView()        // сначала настраиваем таблицу и dataSource
        setupDoubleTapGesture() // потом жест
        bindViewModel()
        viewModel.loadPosts()   // потом данные
    }
    
    // MARK: - Setup
    
    private func setupTableView() {
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        tableView.pinAdaptiveWidth(in: view, horizontalPadding: 0)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.tableHeaderView = storiesBarView
        storiesBarView.onStorySelected = { [weak self] story in
            let viewer = StoryViewerViewController(story: story)
            self?.present(viewer, animated: true)
        }
    }
    
    private func setupDoubleTapGesture() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        tableView.addGestureRecognizer(doubleTap)
    }
    
    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] state in
            self?.handle(state: state)
        }
    }
    
    private func handle(state: FeedViewState) {
        switch state {
        case .idle:
            break
        case .loading:
            loadingIndicator.startAnimating()
        case .loaded:
            loadingIndicator.stopAnimating()
            storiesBarView.update(with: viewModel.posts)
            tableView.reloadData()
        case .failed(let message):
            loadingIndicator.stopAnimating()
            showAlert(title: "common.error".localized, message: message)
        case .alreadyInFavorites:
            showAlert(title: "feed.alert.already_favorite.title".localized, message: "feed.alert.already_favorite.message".localized)
        case .addedToFavorites:
            showAlert(title: "feed.alert.added.title".localized, message: "feed.alert.added.message".localized)
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        viewModel.addToFavorites(at: indexPath.row)
    }
    
    @objc private func likeButtonTapped(_ sender: UIButton) {
        viewModel.toggleLike(at: sender.tag)
    }
    
    @objc private func composeButtonTapped() {
        let composeVC = ComposePostViewController()
        composeVC.onPostCreated = { [weak self] in
            self?.viewModel.loadPosts()
        }
        let nav = UINavigationController(rootViewController: composeVC)
        present(nav, animated: true)
    }
    
    // MARK: - Helpers
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension FeedViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Стиль .subtitle обязателен чтобы detailTextLabel отображался
        var cell = tableView.dequeueReusableCell(withIdentifier: "subtitleCell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "subtitleCell")
        }
        
        let post = viewModel.posts[indexPath.row]
        
        cell?.textLabel?.text = post.description
        cell?.textLabel?.numberOfLines = 2
        cell?.textLabel?.font = AppFonts.body
        
        let likesText = "likes_count".localized(count: post.likes)
        cell?.detailTextLabel?.text = "feed.cell.subtitle_format".localized(post.author, likesText, post.views)
        cell?.detailTextLabel?.font = AppFonts.caption
        cell?.detailTextLabel?.textColor = AppColors.secondaryText
        
        // Пост из Realm — картинка уже под рукой (JPEG-данные или имя ассета уже разрешены в PostsService)
        cell?.imageView?.image = post.image
        
        let likeButton = UIButton(type: .system)
        let isLiked = viewModel.isPostLiked(at: indexPath.row)
        likeButton.setImage(UIImage(systemName: isLiked ? "heart.fill" : "heart"), for: .normal)
        likeButton.tintColor = isLiked ? .systemRed : AppColors.secondaryText
        likeButton.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        likeButton.tag = indexPath.row
        likeButton.addTarget(self, action: #selector(likeButtonTapped(_:)), for: .touchUpInside)
        cell?.accessoryView = likeButton
        
        return cell ?? UITableViewCell()
    }
}

// MARK: - UITableViewDelegate

extension FeedViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
