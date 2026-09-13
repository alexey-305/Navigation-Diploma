//
//  AppTypography.swift
//  Navigation
//

import UIKit

/// Единый стайлгайд шрифтов — по аналогии с AppColors (ExtensionUIColor.swift).
/// Использует системные шрифты с фиксированными размерами и весами, чтобы текст
/// выглядел одинаково на всех экранах приложения.
enum AppFonts {
    /// Крупный заголовок — имя пользователя в шапке профиля, заголовок деталей поста
    static let largeTitle = UIFont.systemFont(ofSize: 28, weight: .bold)
    
    /// Заголовок экрана / карточки — заголовок в списке базы знаний, автор поста
    static let title = UIFont.systemFont(ofSize: 20, weight: .bold)
    
    /// Подзаголовок — второстепенные заголовки, статус в профиле
    static let headline = UIFont.systemFont(ofSize: 17, weight: .semibold)
    
    /// Обычный текст — описание поста, текст цитаты
    static let body = UIFont.systemFont(ofSize: 16, weight: .regular)
    
    /// Второстепенный текст — лайки/просмотры, подписи под элементами
    static let callout = UIFont.systemFont(ofSize: 14, weight: .regular)
    
    /// Мелкий текст — таймстемпы, футеры, подсказки
    static let caption = UIFont.systemFont(ofSize: 12, weight: .regular)
    
    /// Текст на кнопках
    static let button = UIFont.systemFont(ofSize: 16, weight: .semibold)
}
