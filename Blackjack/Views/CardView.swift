import SwiftUI

struct CardView: View {
    static let width: CGFloat = 72
    static let height: CGFloat = 104

    let card: Card
    let isFaceDown: Bool

    private let shape = RoundedRectangle(cornerRadius: 8)

    var body: some View {
        ZStack {
            if isFaceDown {
                back
            } else {
                front
            }
        }
        .frame(width: Self.width, height: Self.height)
        .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
        .animation(.easeInOut(duration: 0.2), value: isFaceDown)
        .accessibilityElement()
        .accessibilityLabel(isFaceDown ? "Face-down card" : "\(card.rank) of \(card.suit)")
    }

    private var front: some View {
        ZStack(alignment: .topLeading) {
            shape.fill(.white)

            VStack(spacing: 0) {
                Text(card.rank.label)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(card.suit.symbol)
                    .font(.system(size: 15))
            }
            .padding(6)

            Text(card.suit.symbol)
                .font(.system(size: 38))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .foregroundStyle(card.suit.isRed ? Color.red : Color.black)
    }

    private var back: some View {
        ZStack {
            shape.fill(Color(red: 0.14, green: 0.2, blue: 0.42))
            shape.inset(by: 5).stroke(.white.opacity(0.6), lineWidth: 1.5)
        }
    }
}

private extension Rank {
    var label: String {
        switch self {
        case .ace: "A"
        case .jack: "J"
        case .queen: "Q"
        case .king: "K"
        default: "\(points)"
        }
    }
}

private extension Suit {
    // U+FE0E asks for the text glyph, so these don't render as emoji.
    var symbol: String {
        switch self {
        case .hearts: "\u{2665}\u{FE0E}"
        case .diamonds: "\u{2666}\u{FE0E}"
        case .clubs: "\u{2663}\u{FE0E}"
        case .spades: "\u{2660}\u{FE0E}"
        }
    }

    var isRed: Bool {
        self == .hearts || self == .diamonds
    }
}
