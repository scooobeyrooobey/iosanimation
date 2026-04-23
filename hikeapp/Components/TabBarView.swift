import SwiftUI

enum AppTab: String, CaseIterable {
    case explore = "Explore"
    case navigate = "Navigate"
    case profile = "Profile"

    var iconName: String {
        switch self {
        case .explore:  return "IconPlanet"
        case .navigate: return "IconMap"
        case .profile:  return "IconFace"
        }
    }
}

struct TabBarView: View {
    @Binding var selected: AppTab
    /// Optional namespace for drop-landing morph on the Profile tab.
    var namespace: Namespace.ID? = nil

    var body: some View {
        GlassGroup {
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.leading, 2)
            .padding(.trailing, 10)
            // Apple spec: BG extends 4pt beyond the pill on each side (Figma node BG x:-4, y:-4)
            .padding(4)
            .glassCapsule()
        }
        .padding(.horizontal, 25)
        .padding(.top, Metrics.tabBarTopInset)
        .padding(.bottom, Metrics.tabBarBottomInset)
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0x060C06).opacity(0), location: 0.00),
                    .init(color: Color(hex: 0x060C06).opacity(0.8), location: 0.45),
                    .init(color: Color(hex: 0x050904).opacity(0.8), location: 1.00),
                ],
                startPoint: .top, endPoint: .bottom
            )
            // Extend the solid lower half of the gradient into the home-indicator
            // safe area so scroll content can't peek through underneath.
            .ignoresSafeArea(.container, edges: .bottom)
            .allowsHitTesting(false)
        )
    }

    @ViewBuilder
    private func tabButton(_ tab: AppTab) -> some View {
        let isActive = selected == tab
        Button {
            selected = tab
        } label: {
            VStack(spacing: 1) {
                Image(tab.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(height: 28)
                    .foregroundStyle(isActive ? AppColor.accent : AppColor.textWhite)
                Text(tab.rawValue)
                    .font(.tabLabel())
                    .foregroundStyle(isActive ? AppColor.accent : AppColor.textWhite)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 7)
            .frame(width: Metrics.tabWidth)
            .background(
                isActive
                ? Capsule().fill(Color(hex: 0x121212)).padding(.horizontal, -2)
                : nil
            )
        }
        .buttonStyle(PressableButtonStyle(pressedScale: 0.9))
    }
}
