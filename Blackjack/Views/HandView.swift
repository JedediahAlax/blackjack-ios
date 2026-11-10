import SwiftUI

struct HandView: View {
    let title: String
    let cards: [Card]
    let totalText: String?
    var hidesHoleCard = false

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.headline)

                if let totalText {
                    Text(totalText)
                        .font(.subheadline.bold().monospacedDigit())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.25), in: .capsule)
                }
            }
            .frame(height: 28)

            // Identified by position, because two decks can deal two identical cards.
            HStack(spacing: cards.count <= 4 ? 8 : -40) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    // The hole card is always the dealer's second card.
                    CardView(card: card, isFaceDown: hidesHoleCard && index == 1)
                        .transition(.asymmetric(insertion: .offset(y: -24).combined(with: .opacity), removal: .opacity))
                }
            }
            .frame(height: CardView.height)
            .animation(.easeOut(duration: 0.25), value: cards.count)
        }
    }
}
