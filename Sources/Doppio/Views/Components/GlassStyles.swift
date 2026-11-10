import SwiftUI
import AppKit

/// Нативная подложка системного стекла macOS (NSVisualEffectView с размытием фона за окном)
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

/// Стиль карточки в стандартах Apple macOS Control Center (системное полупрозрачное стекло Liquid Glass)
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 10
    var isSelected: Bool = false
    var isAccent: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        isSelected && isAccent
                            ? Color.orange.opacity(0.14)
                            : Color.primary.opacity(0.045)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        isSelected && isAccent
                            ? AnyShapeStyle(Color.orange.opacity(0.45))
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.22),
                                        Color.white.opacity(0.06),
                                        Color.primary.opacity(0.06)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            ),
                        lineWidth: 0.5
                    )
                    .allowsHitTesting(false)
            )
    }
}

/// Стеклянная подложка-трек для сегментированных переключателей в стиле macOS Control Center
struct GlassSegmentTrackModifier: ViewModifier {
    var cornerRadius: CGFloat = 7

    func body(content: Content) -> some View {
        content
            .padding(2.5)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    .allowsHitTesting(false)
            )
    }
}

/// Системный стеклянный стиль для капсульных бейджей
struct GlassCapsuleModifier: ViewModifier {
    var isAccent: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                Capsule(style: .continuous)
                    .fill(isAccent ? Color.orange.opacity(0.15) : Color.primary.opacity(0.05))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        isAccent
                            ? Color.orange.opacity(0.35)
                            : Color.primary.opacity(0.09),
                        lineWidth: 0.5
                    )
                    .allowsHitTesting(false)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 10, isSelected: Bool = false, isAccent: Bool = false) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, isSelected: isSelected, isAccent: isAccent))
    }

    func glassSegmentTrack(cornerRadius: CGFloat = 7) -> some View {
        modifier(GlassSegmentTrackModifier(cornerRadius: cornerRadius))
    }

    func glassCapsule(isAccent: Bool = false) -> some View {
        modifier(GlassCapsuleModifier(isAccent: isAccent))
    }
}

/// Стеклянный стиль для интерактивных кнопок в стиле macOS с поддержкой Hover и нажатия
struct GlassButtonStyle: ButtonStyle {
    var isSelected: Bool = false
    var isAccent: Bool = false
    var cornerRadius: CGFloat = 7

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
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            isSelected
                                ? (isAccent
                                   ? Color.orange.opacity(isHovered ? 0.22 : 0.16)
                                   : Color.primary.opacity(isHovered ? 0.14 : 0.10))
                                : Color.primary.opacity(
                                    configuration.isPressed
                                        ? 0.12
                                        : (isHovered ? 0.08 : 0.04)
                                )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            isSelected
                                ? (isAccent
                                   ? Color.orange.opacity(isHovered ? 0.60 : 0.45)
                                   : Color.primary.opacity(isHovered ? 0.22 : 0.15))
                                : Color.primary.opacity(isHovered ? 0.12 : 0.07),
                            lineWidth: 0.5
                        )
                        .allowsHitTesting(false)
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
