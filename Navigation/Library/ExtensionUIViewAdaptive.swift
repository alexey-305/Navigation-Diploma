//
//  ExtensionUIViewAdaptive.swift
//  Navigation
//

import UIKit

public extension UIView {
    /// Ограничивает ширину view заданным максимумом и центрирует его в parent.
    ///
    /// На iPhone (узкий экран, compact width) ограничение по максимальной ширине
    /// никогда не срабатывает — view растягивается на всю ширину как обычно.
    /// На iPad (широкий экран) контент центрируется колонкой фиксированной ширины,
    /// а не растягивается на весь экран — длинные списки и текст остаются читаемыми,
    /// вместо одной строки на весь iPad-экран.
    ///
    /// Работает через приоритеты Auto Layout, а не через ручную проверку
    /// horizontalSizeClass — поэтому адаптируется сама, включая мультизадачность
    /// (Split View/Slide Over на iPad), где ширина окна меняется на лету.
    @discardableResult
    func pinAdaptiveWidth(in parent: UIView, maxWidth: CGFloat = 700, horizontalPadding: CGFloat = 16) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        
        // "Хочет" быть на всю ширину — но это низкоприоритетное желание
        let fullWidthLeading = leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: horizontalPadding)
        fullWidthLeading.priority = .defaultHigh
        let fullWidthTrailing = trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -horizontalPadding)
        fullWidthTrailing.priority = .defaultHigh
        
        let constraints = [
            centerXAnchor.constraint(equalTo: parent.centerXAnchor),
            widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
            leadingAnchor.constraint(greaterThanOrEqualTo: parent.leadingAnchor, constant: horizontalPadding),
            trailingAnchor.constraint(lessThanOrEqualTo: parent.trailingAnchor, constant: -horizontalPadding),
            fullWidthLeading,
            fullWidthTrailing
        ]
        
        NSLayoutConstraint.activate(constraints)
        return constraints
    }
}
