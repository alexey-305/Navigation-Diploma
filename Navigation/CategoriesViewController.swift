import UIKit

class CategoriesViewController: UIViewController {
    
    private let viewModel: CategoriesViewModel
    
    init(viewModel: CategoriesViewModel = AppDependencyContainer.shared.makeCategoriesViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "categories.title".localized
        setupTableView()
        bindViewModel()
        viewModel.loadCategories()
    }
    
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
    
    private func bindViewModel() {
        viewModel.onCategoriesChanged = { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

extension CategoriesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let category = viewModel.categories[indexPath.row]
        cell.textLabel?.text = "\(category.name) (\(category.quotesCount))"
        cell.textLabel?.font = AppFonts.body
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let category = viewModel.categories[indexPath.row]
        let vc = CategoryQuotesViewController(categoryName: category.name)
        navigationController?.pushViewController(vc, animated: true)
    }
}
