import UIKit

class CategoryQuotesViewController: UIViewController {
    
    private let viewModel: CategoryQuotesViewModel
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()
    
    init(categoryName: String) {
        self.viewModel = AppDependencyContainer.shared.makeCategoryQuotesViewModel(categoryName: categoryName)
        super.init(nibName: nil, bundle: nil)
        title = categoryName
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupTableView()
        bindViewModel()
        viewModel.loadQuotes()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.pinAdaptiveWidth(in: view, horizontalPadding: 0)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.dataSource = self
    }
    
    private func bindViewModel() {
        viewModel.onQuotesChanged = { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

extension CategoryQuotesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.quotes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = viewModel.quotes[indexPath.row].text
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = AppFonts.body
        return cell
    }
}
