import Testing
@testable import Blackjack

struct ShoeTests {

    @Test(arguments: 1...8)
    func shoeHoldsFiftyTwoCardsPerDeck(deckCount: Int) {
        #expect(Shoe(deckCount: deckCount).remainingCount == 52 * deckCount)
    }

    @Test(arguments: [1, 2, 8])
    func everyCardAppearsOncePerDeck(deckCount: Int) {
        var shoe = Shoe(deckCount: deckCount)
        let dealt = drawAll(from: &shoe)

        for suit in Suit.allCases {
            for rank in Rank.allCases {
                let copies = dealt.filter { $0.rank == rank && $0.suit == suit }.count
                #expect(copies == deckCount, "\(rank) of \(suit)")
            }
        }
    }

    // Catches a shoe that never gets shuffled: two of those would deal
    // in exactly the same order.
    @Test func newShoesAreShuffled() {
        var first = Shoe(deckCount: 2)
        var second = Shoe(deckCount: 2)

        let firstRanks = drawAll(from: &first).map(\.rank)
        let secondRanks = drawAll(from: &second).map(\.rank)

        #expect(firstRanks != secondRanks)
    }

    @Test func stackedShoeDealsCardsInTheOrderGiven() {
        var shoe = Shoe(cards: [
            Card(rank: .ace, suit: .spades),
            Card(rank: .five, suit: .hearts),
            Card(rank: .king, suit: .diamonds),
        ])

        let dealt = [shoe.draw(), shoe.draw(), shoe.draw()]

        #expect(dealt.map(\.rank) == [.ace, .five, .king])
        #expect(dealt.map(\.suit) == [.spades, .hearts, .diamonds])
        #expect(shoe.remainingCount == 0)
    }

    @Test func newShoeDoesNotNeedReshuffle() {
        #expect(!Shoe(deckCount: 2).needsReshuffle)
    }

    @Test func shoeNeedsReshuffleOnceFewerThanAQuarterOfItsCardsRemain() {
        // 104 cards, so the cut card sits 26 cards from the end.
        var shoe = Shoe(deckCount: 2)
        for _ in 0..<78 {
            _ = shoe.draw()
        }

        #expect(shoe.remainingCount == 26)
        #expect(!shoe.needsReshuffle)

        _ = shoe.draw()

        #expect(shoe.needsReshuffle)
    }

    private func drawAll(from shoe: inout Shoe) -> [Card] {
        var dealt: [Card] = []
        while shoe.remainingCount > 0 {
            dealt.append(shoe.draw())
        }
        return dealt
    }
}
