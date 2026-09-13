import Foundation

/// Бизнес-логика фильтра избранного — вынесена из View Controller, чтобы не
/// смешивать построение предиката/заголовка с управлением NSFetchedResultsController.
/// Сам FRC и его делегат остаются во FavoritesViewController: это View-слой
/// (анимации таблицы), не бизнес-логика, и разрывать эту связку ради формальной
/// чистоты MVVM было бы искусственным усложнением.
final class FavoritesViewModel {
    
    private(set) var isFiltering = false
    private(set) var currentFilterAuthor: String?
    
    var navigationTitle: String {
        if isFiltering, let author = currentFilterAuthor {
            return "favorites.filter.applied_format".localized(author)
        }
        return "favorites.title".localized
    }
    
    var filterPredicate: NSPredicate? {
        guard isFiltering, let author = currentFilterAuthor, !author.isEmpty else { return nil }
        return NSPredicate(format: "authorName CONTAINS[cd] %@", author)
    }
    
    /// Возвращает false, если введённое значение невалидно (пустая строка) — 
    /// вызывающая сторона должна показать ошибку и не применять фильтр
    @discardableResult
    func applyFilter(author: String) -> Bool {
        guard !author.isEmpty else { return false }
        currentFilterAuthor = author
        isFiltering = true
        return true
    }
    
    func clearFilter() {
        currentFilterAuthor = nil
        isFiltering = false
    }
}
