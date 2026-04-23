import SwiftUI

struct DifficultyDots: View {
    /// 0...4 — number of "filled" dots (colored). The Figma design shows a 4-dot gradient scale.
    let level: Int

    private let palette: [Color] = [
        Color(hex: 0x5FF453), // green
        Color(hex: 0xFFC93B), // yellow
        Color(hex: 0xFF7A3B), // orange
        Color(hex: 0xD92B36)  // red (4th / hardest)
    ]
    private let inactive = Color(hex: 0xA5A5A5).opacity(0.5)

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { idx in
                Circle()
                    .fill(idx < level ? palette[idx] : inactive)
                    .frame(width: 8, height: 8)
            }
        }
    }
}
