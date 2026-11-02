import SwiftUI

/// Стиль стеклянной карточки (Liquid Glass / Material) в стандартах macOS 27 / iOS 2026
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14
    var isSelected: Bool = false
    var isAccent: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        isSelected && isAccent
                            ? Color.orange.opacity(0.14)
                            : Color.primary.opacity(0.04)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                // Верхний блик стекла (Specular Sheen)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.08), location: 0),
                                .init(color: Color.white.opacity(0.02), location: 0.35),
                                .init(color: Color.clear, location: 0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
            )
            .overlay(
                // Тонкая оптическая кромка стекла с преломлением
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        isSelected && isAccent
                            ? LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.80),
                                    Color.orange.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color.white.opacity(0.24),
                                    Color.white.opacity(0.08),
                                    Color.black.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: 0.75
                    )
                    .allowsHitTesting(false)
            )
            .shadow(
                color: isSelected && isAccent
                    ? Color.orange.opacity(0.18)
                    : Color.black.opacity(0.03),
                radius: isSelected && isAccent ? 8 : 4,
                y: 1.5
            )
    }
}

/// Стеклянная подложка-трек для сегментированных переключателей
struct GlassSegmentTrackModifier: ViewModifier {
    var cornerRadius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 0.75)
                    .allowsHitTesting(false)
            )
    }
}

/// Стеклянный стиль для капсульных бейджей
struct GlassCapsuleModifier: ViewModifier {
    var isAccent: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                Capsule(style: .continuous)
                    .fill(isAccent ? Color.orange.opacity(0.14) : Color.primary.opacity(0.05))
                    .background(
                        Capsule(style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        isAccent
                            ? Color.orange.opacity(0.40)
                            : Color.white.opacity(0.20),
                        lineWidth: 0.75
                    )
                    .allowsHitTesting(false)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 14, isSelected: Bool = false, isAccent: Bool = false) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, isSelected: isSelected, isAccent: isAccent))
    }

    func glassSegmentTrack(cornerRadius: CGFloat = 10) -> some View {
        modifier(GlassSegmentTrackModifier(cornerRadius: cornerRadius))
    }

    func glassCapsule(isAccent: Bool = false) -> some View {
        modifier(GlassCapsuleModifier(isAccent: isAccent))
    }
}

/// Стеклянный стиль для интерактивных кнопок с поддержкой Hover и Spring-анимации
struct GlassButtonStyle: ButtonStyle {
    var isSelected: Bool = false
    var isAccent: Bool = false
    var cornerRadius: CGFloat = 10

    func makeBody(configuration: Configuration) -> some View {
        GlassButtonBody(
            configuration: configuration,
            isSelected: isSelected,
            isAccent: isAccent,
            cornerRadius: cornerRadius
        )
    }

    private struct GlassButtonBody: View {
        let configuration: Configuration
        let isSelected: Bool
        let isAccent: Bool
        let cornerRadius: CGFloat

        @State private var isHovered = false

        var body: some View {
            configuration.label
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                isSelected
                                    ? (isAccent
                                       ? Color.orange.opacity(isHovered ? 0.24 : 0.18)
                                       : Color.primary.opacity(isHovered ? 0.14 : 0.10))
                                    : Color.primary.opacity(
                                        configuration.isPressed
                                            ? 0.12
                                            : (isHovered ? 0.08 : 0.045)
                                    )
                            )

                        // Верхний световой блик кнопки (внутри фона, не перекрывает текст)
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isHovered ? 0.12 : 0.06),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )

                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                isSelected
                                    ? (isAccent
                                       ? Color.orange.opacity(isHovered ? 0.70 : 0.55)
                                       : Color.primary.opacity(isHovered ? 0.30 : 0.20))
                                    : Color.primary.opacity(isHovered ? 0.15 : 0.08),
                                lineWidth: 0.75
                            )
                    }
                )
                .opacity(configuration.isPressed ? 0.85 : 1.0)
                .animation(.easeOut(duration: 0.12), value: isHovered)
                .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
                .onHover { hovering in
                    isHovered = hovering
                }
        }
    }
}
