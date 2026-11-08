struct Shoe {
    private var cards: [Card]
    private let startingCount: Int

    init(cards: [Card]) {
        self.cards = cards.reversed()
        startingCount = cards.count
    }

    init(deckCount: Int) {
        precondition((1...8).contains(deckCount), "Deck count must be 1–8, got \(deckCount)")

        var cards: [Card] = []
        for _ in 0..<deckCount {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    cards.append(Card(rank: rank, suit: suit))
                }
            }
        }
        cards.shuffle()
        self.init(cards: cards)
    }

    var remainingCount: Int {
        cards.count
    }

    // The cut card: time to reshuffle once fewer than a quarter of the cards are left.
    var needsReshuffle: Bool {
        remainingCount * 4 < startingCount
    }

    mutating func draw() -> Card {
        precondition(!cards.isEmpty, "Can't draw from an empty shoe")
        return cards.removeLast()
    }
}
