import SwiftUI
import UIKit

/// UILabel wrapper for exact line-height control via NSParagraphStyle.
/// SwiftUI's Text ignores NSParagraphStyle minimumLineHeight / maximumLineHeight,
/// so this is required when lineHeight must be smaller than the font point size.
struct TightTitleLabel: UIViewRepresentable {
    let text: String
    let fontName: String
    let fontSize: CGFloat
    let lineHeight: CGFloat
    let color: Color
    var numberOfLines: Int = 2
    var maxWidth: CGFloat = 265

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = numberOfLines
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.clipsToBounds = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        let uiFont = UIFont(name: fontName, size: fontSize)
            ?? UIFont.systemFont(ofSize: fontSize, weight: .black)

        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        paragraph.alignment = .center

        let attrs: [NSAttributedString.Key: Any] = [
            .font: uiFont,
            .foregroundColor: UIColor(color),
            .paragraphStyle: paragraph,
        ]
        label.attributedText = NSAttributedString(string: text, attributes: attrs)
        label.preferredMaxLayoutWidth = maxWidth
    }
}
