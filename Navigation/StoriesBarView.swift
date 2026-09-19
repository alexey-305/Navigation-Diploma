import UIKit

/// Горизонтальная лента "историй" вверху ленты — по одной на каждого автора
/// с постом (аватар — картинка последнего поста этого автора). Тап открывает
/// полноэкранный просмотр на несколько секунд, как в VK/Instagram.
final class StoriesBarView: UIView {
    
    struct Story {
        let author: String
        let image: UIImage?
    }
    
    var onStorySelected: ((Story) -> Void)?
    
    private var stories: [Story] = []
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 76, height: 92)
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(StoryBubbleCell.self, forCellWithReuseIdentifier: StoryBubbleCell.reuseIdentifier)
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    /// Строит по одной "истории" на каждого уникального автора (картинка его
    /// последнего поста), сохраняя порядок первого появления в ленте
    func update(with posts: [Post]) {
        var seenAuthors = Set<String>()
        var result: [Story] = []
        
        for post in posts {
            guard !seenAuthors.contains(post.author) else { continue }
            seenAuthors.insert(post.author)
            result.append(Story(author: post.author, image: post.image))
        }
        
        stories = result
        collectionView.reloadData()
    }
}

extension StoriesBarView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        stories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: StoryBubbleCell.reuseIdentifier,
            for: indexPath
        ) as? StoryBubbleCell else {
            return UICollectionViewCell()
        }
        
        let story = stories[indexPath.item]
        cell.configure(image: story.image, name: story.author)
        return cell
    }
}

extension StoriesBarView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        onStorySelected?(stories[indexPath.item])
    }
}
