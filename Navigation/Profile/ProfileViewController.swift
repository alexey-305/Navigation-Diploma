import UIKit
import FirebaseAuth

final class ProfileViewController: UIViewController {
    
    weak var coordinator: ProfileCoordinator?
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let postsService: PostsServiceProtocol
    private var posts: [Post] = []
    
    init(postsService: PostsServiceProtocol = AppDependencyContainer.shared.postsService) {
        self.postsService = postsService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Показываем реального авторизованного пользователя вместо тестового
    private var currentUser: User {
        User(
            login: Auth.auth().currentUser?.uid ?? "",
            fullName: Auth.auth().currentUser?.email ?? "Гость",
            avatar: UIImage(named: "avatar") ?? UIImage(),
            status: "Waiting for something..."
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "Profile"
        
        setupTableView()
        setupConstraints()
        setupDragAndDrop()
        setupLogoutButton()
        loadPosts()
        
        tableView.estimatedRowHeight = 400
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func loadPosts() {
        postsService.fetchPosts { [weak self] result in
            guard let self = self else { return }
            if case .success(let posts) = result {
                self.posts = posts
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func setupLogoutButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "rectangle.portrait.and.arrow.right"),
            style: .plain,
            target: self,
            action: #selector(logOutButtonTapped)
        )
    }
    
    @objc private func logOutButtonTapped() {
        let alert = UIAlertController(title: "Выйти из аккаунта?", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { _ in
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.showInitialScreenAfterLogOut()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: "PostCell")
        tableView.separatorStyle = .none
    }
    
    private func setupConstraints() {
        tableView.pinAdaptiveWidth(in: view, horizontalPadding: 0)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Задача 1, пункт 1: включаем drag & drop у таблицы
    private func setupDragAndDrop() {
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self
    }
}

// MARK: - UITableViewDataSource
extension ProfileViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostTableViewCell else {
            return UITableViewCell()
        }
        cell.configPostArray(post: posts[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = ProfileHeaderView()
        header.configure(with: currentUser)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 220
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        coordinator?.showPostDetails(posts[indexPath.row])
    }
}

// MARK: - UITableViewDragDelegate (Задача 1, пункт 3)
extension ProfileViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let post = posts[indexPath.row]
        
        let textProvider = NSItemProvider(object: post.description as NSString)
        let textDragItem = UIDragItem(itemProvider: textProvider)
        textDragItem.localObject = post
        
        // Картинка есть под рукой только у локальных/уже сохранённых постов —
        // на случай, если она почему-то не разрешилась (image == nil),
        // перетаскиваем только текст
        guard let image = post.image else {
            return [textDragItem]
        }
        
        let imageProvider = NSItemProvider(object: image)
        let imageDragItem = UIDragItem(itemProvider: imageProvider)
        imageDragItem.localObject = post
        
        return [imageDragItem, textDragItem]
    }
}

// MARK: - UITableViewDropDelegate (Задача 1, пункт 4-7)
extension ProfileViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: UIImage.self) && session.canLoadObjects(ofClass: NSString.self)
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        UITableViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        // Пункт 4: рассчитываем место вставки из coordinator
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: max(section, 0))
            destinationIndexPath = IndexPath(row: row, section: max(section, 0))
        }
        
        print("📍 Drop приземлился на indexPath: \(destinationIndexPath)")
        
        // Пункт 5: загружаем картинки и строки из coordinator
        var droppedImage: UIImage?
        var droppedText: String?
        let loadGroup = DispatchGroup()
        
        loadGroup.enter()
        coordinator.session.loadObjects(ofClass: UIImage.self) { items in
            droppedImage = items.first as? UIImage
            loadGroup.leave()
        }
        
        loadGroup.enter()
        coordinator.session.loadObjects(ofClass: NSString.self) { items in
            droppedText = items.first as? String
            loadGroup.leave()
        }
        
        loadGroup.notify(queue: .main) { [weak self] in
            guard let self = self, let image = droppedImage, let text = droppedText else { return }
            
            // Пункт 6: создаём пост через тот же PostsService, что и лента —
            // одно хранилище постов на всё приложение (Realm), а не отдельный массив.
            // Пункт 7: как только пост реально сохранён — обновляем таблицу
            self.postsService.addPost(author: "Drag&Drop", description: text, image: image) { [weak self] _ in
                self?.loadPosts()
            }
        }
    }
}
