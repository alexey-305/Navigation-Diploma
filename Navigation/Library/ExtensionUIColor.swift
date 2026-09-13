//
//  ExtensionUIColor.swift
//  Navigation
//

import UIKit

public extension UIColor {
    /// Создаёт динамический цвет, который сам переключается между light и dark
    /// вариантами в зависимости от текущей темы (UITraitCollection.userInterfaceStyle)
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
}

/// Собственная палитра приложения для Light/Dark темы.
/// Каждый цвет — это dynamicColor(light:dark:), собранный через функцию выше.
public enum AppColors {
    /// Основной фон экрана
    static let background = UIColor.dynamicColor(
        light: .white,
        dark: .black
    )

    /// Фон карточек, полей ввода, шапки профиля
    static let secondaryBackground = UIColor.dynamicColor(
        light: UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1.0),
        dark: UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1.0)
    )

    /// Основной текст
    static let primaryText = UIColor.dynamicColor(
        light: .black,
        dark: .white
    )

    /// Второстепенный текст (описания, статусы, подписи)
    static let secondaryText = UIColor.dynamicColor(
        light: UIColor(red: 108/255, green: 108/255, blue: 112/255, alpha: 1.0),
        dark: UIColor(red: 152/255, green: 152/255, blue: 157/255, alpha: 1.0)
    )

    /// Разделители и рамки полей ввода
    static let separator = UIColor.dynamicColor(
        light: UIColor(red: 200/255, green: 200/255, blue: 205/255, alpha: 1.0),
        dark: UIColor(red: 60/255, green: 60/255, blue: 62/255, alpha: 1.0)
    )

    /// Акцентный цвет для кнопок и активных элементов
    static let accent = UIColor.dynamicColor(
        light: UIColor(red: 72/255, green: 133/255, blue: 204/255, alpha: 1.0),
        dark: UIColor(red: 94/255, green: 151/255, blue: 219/255, alpha: 1.0)
    )

    /// Цвет текста на акцентном фоне (кнопки)
    static let onAccentText = UIColor.dynamicColor(
        light: .white,
        dark: .white
    )

    /// Рамка аватара
    static let avatarBorder = UIColor.dynamicColor(
        light: .white,
        dark: UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1.0)
    )
}
