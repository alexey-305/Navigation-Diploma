import UIKit
import CoreData

class FavoritesViewController: UIViewController {
    
    // MARK: - Properties
    
    private let coreDataManager = CoreDataManager.shared
    private let viewModel = FavoritesViewModel()
    
    // MARK: - FetchedResultsController
    
    private lazy var fetchedResultsController: NSFetchedResultsController<FavoritePost> = {
        let fetchRequest: NSFetchRequest<FavoritePost> = FavoritePost.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchBatchSize = 20
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: coreDataManager.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        return controller // performFetch вызывается отдельно в viewDidLoad
    }()
    
    // MARK: - UI Elements
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        // Не регистрируем UITableViewCell.self — используем .subtitle стиль через dequeue вручную
        return tv
    }()
    
    private lazy var filterButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: "🔍",
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped)
        )
    }()
    
    private lazy var clearFilterButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: "✖️",
            style: .plain,
            target: self,
            action: #selector(clearFilterTapped)
        )
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "favorites.title".localized
        
        navigationItem.rightBarButtonItems = [filterButton, clearFilterButton]
        
        setupTableView()
        performInitialFetch()
    }
    
    // viewWillAppear убран — FRC сам отслеживает изменения через делегат
    
    // MARK: - Setup
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.pinAdaptiveWidth(in: view, horizontalPadding: 0)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    // MARK: - Fetch
    
    /// Первоначальный fetch при загрузке экрана
    private func performInitialFetch() {
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print("❌ Ошибка выполнения fetch: \(error)")
        }
    }
    
    /// Обновление предиката и повторный fetch (только при смене фильтра)
    private func updateFetchRequest() {
        fetchedResultsController.fetchRequest.predicate = viewModel.filterPredicate
        
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print("❌ Ошибка обновления fetch: \(error)")
        }
    }
    
    // MARK: - Actions
    
    @objc private func filterButtonTapped() {
        let alert = UIAlertController(
            title: "favorites.filter.title".localized,
            message: "favorites.filter.message".localized,
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "favorites.filter.placeholder".localized
            textField.autocapitalizationType = .words
        }
        
        let applyAction = UIAlertAction(title: "favorites.filter.apply".localized, style: .default) { [weak self] _ in
            guard let self = self,
                  let text = alert.textFields?.first?.text,
                  self.viewModel.applyFilter(author: text) else {
                self?.showAlert(title: "common.error".localized, message: "favorites.filter.error_empty".localized)
                return
            }
            self.title = self.viewModel.navigationTitle
            self.updateFetchRequest()
        }
        
        let cancelAction = UIAlertAction(title: "common.cancel".localized, style: .cancel)
        
        alert.addAction(applyAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @objc private func clearFilterTapped() {
        viewModel.clearFilter()
        title = viewModel.navigationTitle
        updateFetchRequest()
        showAlert(title: "favorites.filter.cleared.title".localized, message: "favorites.filter.cleared.message".localized)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension FavoritesViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Используем стиль .subtitle чтобы detailTextLabel отображался
        var cell = tableView.dequeueReusableCell(withIdentifier: "subtitleCell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "subtitleCell")
        }
        
        let post = fetchedResultsController.object(at: indexPath)
        
        cell?.textLabel?.text = post.titleText ?? "favorites.post.untitled".localized
        cell?.textLabel?.numberOfLines = 2
        cell?.textLabel?.font = AppFonts.body
        
        let authorText = post.authorName ?? "favorites.post.unknown_author".localized
        let likesText = "likes_count".localized(count: Int(post.likesCount))
        cell?.detailTextLabel?.text = "favorites.cell.subtitle_format".localized(authorText, likesText)
        cell?.detailTextLabel?.font = AppFonts.caption
        cell?.detailTextLabel?.textColor = AppColors.secondaryText
        
        return cell ?? UITableViewCell()
    }
}

// MARK: - UITableViewDelegate

extension FavoritesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "common.delete".localized
        ) { [weak self] _, _, completion in
            guard let self = self else {
                completion(false)
                return
            }
            // Объект берётся из FRC — удаляем его через CoreDataManager
            // FRC-делегат автоматически анимирует удаление строки
            let post = self.fetchedResultsController.object(at: indexPath)
            self.coreDataManager.deletePost(post)
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension FavoritesViewController: NSFetchedResultsControllerDelegate {
    
    /// Вызывается перед началом изменений — открываем batch-обновление таблицы
    func controllerWillChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        tableView.beginUpdates()
    }
    
    /// Вызывается после всех изменений — закрываем batch и применяем анимации
    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        tableView.endUpdates()
    }
    
    /// Вызывается для каждого изменённого объекта
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
            
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
            
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
            tableView.moveRow(at: indexPath, to: newIndexPath)
            
        @unknown default:
            break
        }
    }
}
