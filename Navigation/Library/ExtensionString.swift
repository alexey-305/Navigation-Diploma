//
//  ExtensionString.swift
//  Navigation
//

import Foundation

public extension String {
    /// Локализованная строка по ключу (сам `self` используется как ключ в Localizable.strings)
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Локализованная строка с подстановкой аргументов через String(format:)
    func localized(_ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }

    /// Локализованная строка с учётом множественного числа (использует Localizable.stringsdict)
    func localized(count: Int) -> String {
        String.localizedStringWithFormat(NSLocalizedString(self, comment: ""), count)
    }
}
