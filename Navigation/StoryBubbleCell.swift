import UIKit

final class StoryBubbleCell: UICollectionViewCell {
    
    static let reuseIdentifier = "StoryBubbleCell"
    
    private let ringView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 2.5
        view.layer.borderColor = AppColors.accent.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = AppColors.secondaryBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.caption
        label.textColor = AppColors.primaryText
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        contentView.addSubview(ringView)
        ringView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            ringView.topAnchor.constraint(equalTo: contentView.topAnchor),
            ringView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            ringView.widthAnchor.constraint(equalToConstant: 64),
            ringView.heightAnchor.constraint(equalToConstant: 64),
            
            avatarImageView.topAnchor.constraint(equalTo: ringView.topAnchor, constant: 4),
            avatarImageView.leadingAnchor.constraint(equalTo: ringView.leadingAnchor, constant: 4),
            avatarImageView.trailingAnchor.constraint(equalTo: ringView.trailingAnchor, constant: -4),
            avatarImageView.bottomAnchor.constraint(equalTo: ringView.bottomAnchor, constant: -4),
            
            nameLabel.topAnchor.constraint(equalTo: ringView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        ringView.layer.cornerRadius = ringView.bounds.width / 2
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
    }
    
    func configure(image: UIImage?, name: String) {
        avatarImageView.image = image
        nameLabel.text = name
    }
}
