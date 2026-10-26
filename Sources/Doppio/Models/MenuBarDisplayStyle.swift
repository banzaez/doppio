import Foundation

/// Режим отображения Doppio в строке меню macOS (Menu Bar)
/// Позволяет скрывать текст оставшегося времени для экономии места на экранах с вырезом камеры (Notch)
public enum MenuBarDisplayStyle: String, CaseIterable, Identifiable, Sendable, Codable {
    /// Стандартный: Иконка чашки и оставшееся время (☕️ 45м)
    case standard
    /// Только иконка: Чашка без текста (☕️)
    case iconOnly

    public var id: String { rawValue }
}
