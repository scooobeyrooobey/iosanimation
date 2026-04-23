import SwiftUI

enum LiquidGlassStyle {
    case accent       // green pill with label
    case text         // dark glass pill with label
    case icon         // 48x48 round glass with icon
}

struct LiquidGlassButton<Content: View>: View {
    let style: LiquidGlassStyle
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    init(style: LiquidGlassStyle, action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.action = action
        self.content = content
    }

    var body: some View {
        Button(action: action) {
            switch style {
            case .accent:
                content()
                    .font(.buttonLabel())
                    .foregroundStyle(AppColor.textBlack)
                    .padding(.horizontal, Metrics.buttonPillHPadding)
                    .padding(.vertical, Metrics.buttonPillVPadding)
                    .frame(height: 48)
                    .background(
                        Capsule().fill(AppColor.accent)
                    )
                    .shadow(color: AppColor.accent.opacity(0.2), radius: 24)
            case .text:
                content()
                    .font(.buttonLabel())
                    .foregroundStyle(AppColor.textWhite)
                    .padding(.horizontal, Metrics.buttonPillHPadding)
                    .padding(.vertical, Metrics.buttonPillVPadding)
                    .frame(height: 48)
                    .glassCapsule()
            case .icon:
                content()
                    .foregroundStyle(AppColor.textWhite)
                    .frame(width: Metrics.iconButtonSize, height: Metrics.iconButtonSize)
                    .glassCapsule()
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Press interaction: scale-down + subtle opacity on tap
struct PressableButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.94
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(duration: 0.22, bounce: 0.25), value: configuration.isPressed)
    }
}

// MARK: - iOS 26 Liquid Glass — native `.glassEffect` forced into its dark
// variant. `.preferredColorScheme(.dark)` at the App level does not always
// propagate to the iOS 26 material pipeline (the Liquid Glass effect reads
// the trait collection, not the SwiftUI environment, in some rendering paths).
// Wrapping the glassified view in `.colorScheme(.dark)` forces the material
// to resolve its dark tokens, which kills the bright specular edge highlight
// that otherwise reads as an unwanted glow on very dark backgrounds.
extension View {
    @ViewBuilder
    func glassCapsule() -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular, in: .capsule)
                .colorScheme(.dark)
        } else {
            self
                .background(Capsule().fill(Color.black.opacity(0.35)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
                .shadow(color: .black.opacity(0.12), radius: 40, y: 8)
        }
    }
}

// MARK: - GlassEffectContainer wrapper (groups glass elements so they share one
// backdrop sample — both a perf win and a reliability win during animations).
struct GlassGroup<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer { content() }
        } else {
            content()
        }
    }
}
