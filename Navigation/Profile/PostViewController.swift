import UIKit

class PostViewController: UIViewController {
    
    var post: Post?
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let likesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let viewsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Post Details"
        
        setupViews()
        setupConstraints()
        displayData()
    }
    
    private func setupViews() {
        view.addSubview(authorLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(likesLabel)
        view.addSubview(viewsLabel)
    }
    
    private func setupConstraints() {
        authorLabel.pinAdaptiveWidth(in: view, maxWidth: 600)
        descriptionLabel.pinAdaptiveWidth(in: view, maxWidth: 600)
        
        NSLayoutConstraint.activate([
            authorLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            
            descriptionLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 20),
            
            likesLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            likesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            viewsLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            viewsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func displayData() {
        guard let post = post else { return }
        authorLabel.text = post.author
        descriptionLabel.text = post.description
        likesLabel.text = "❤️ \(post.likes) likes"
        viewsLabel.text = "👁 \(post.views) views"
    }
}
