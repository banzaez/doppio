import Foundation

/// Поддерживаемые языки интерфейса Doppio
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case german = "de"
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case russian = "ru"
    case ukrainian = "uk"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .german:
            return "Deutsch"
        case .english:
            return "English"
        case .spanish:
            return "Español"
        case .french:
            return "Français"
        case .russian:
            return "Русский"
        case .ukrainian:
            return "Українська"
        }
    }

    /// Код эффективного языка для словаря локализации
    public var effectiveCode: String {
        rawValue
    }

    /// Язык по умолчанию на основе предпочтительного языка системы macOS
    public static var defaultLanguage: AppLanguage {
        let detected = detectSystemLanguageCode()
        return AppLanguage(rawValue: detected) ?? .english
    }

    /// Определение языка системы macOS из preferredLanguages
    public static func detectSystemLanguageCode() -> String {
        for lang in Locale.preferredLanguages {
            let lower = lang.lowercased()
            if lower.hasPrefix("uk") { return "uk" }
            if lower.hasPrefix("ru") { return "ru" }
            if lower.hasPrefix("de") { return "de" }
            if lower.hasPrefix("fr") { return "fr" }
            if lower.hasPrefix("es") { return "es" }
            if lower.hasPrefix("en") { return "en" }
        }
        return "en"
    }
}
