import Testing
@testable import Blackjack

struct HandTests {

    @Test func newHandIsEmpty() {
        let hand = Hand()
        #expect(hand.cards.isEmpty)
        #expect(hand.total == 0)
        #expect(!hand.isSoft)
    }

    @Test func addingCardsKeepsTheOrderTheyWereDealt() {
        let hand = makeHand([.king, .ace, .two])
        #expect(hand.cards.map(\.rank) == [.king, .ace, .two])
    }

    @Test(arguments: [
        // Hard totals
        ([Rank.king, .queen], 20, false),
        ([.ten, .six, .ace], 17, false),
        ([.ace, .six, .ten], 17, false),
        ([.ace, .king, .queen], 21, false),
        ([.five, .six, .ace, .ace, .ace, .ace], 15, false),
        // Soft totals
        ([.ace, .six], 17, true),
        ([.ace, .ace], 12, true),
        ([.ace, .ace, .nine], 21, true),
        ([.ace, .nine, .ace], 21, true),
        ([.ace, .ace, .ace, .ace], 14, true),
        ([.ace, .five, .five], 21, true),
    ])
    func totalCountsAnAceAsElevenOnlyWhenItFits(ranks: [Rank], expectedTotal: Int, expectedSoft: Bool) {
        let hand = makeHand(ranks)
        #expect(hand.total == expectedTotal)
        #expect(hand.isSoft == expectedSoft)
    }

    @Test(arguments: [
        ([Rank.king, .queen, .two], true),
        ([.ten, .six, .six], true),
        ([.ace, .ace, .king, .queen], true),
        ([.king, .queen, .ace], false),
        ([.ten, .six, .five], false),
    ])
    func handIsBustOnlyOverTwentyOne(ranks: [Rank], expectedBust: Bool) {
        #expect(makeHand(ranks).isBust == expectedBust)
    }

    // A two-card 21 after a split is not a blackjack, but the game knows
    // about splits, not Hand.
    @Test(arguments: [
        ([Rank.ace, .king], true),
        ([.queen, .ace], true),
        ([.ace, .ten], true),
        ([.ace, .five, .five], false),
        ([.ace, .king, .queen], false),
        ([.king, .five, .ace], false),
        ([.king, .queen], false),
        ([.ace, .nine], false),
    ])
    func blackjackIsTwentyOneWithTwoCards(ranks: [Rank], expectedBlackjack: Bool) {
        #expect(makeHand(ranks).isBlackjack == expectedBlackjack)
    }

    /// Suits don't affect scoring, so every test card is a spade.
    private func makeHand(_ ranks: [Rank]) -> Hand {
        var hand = Hand()
        for rank in ranks {
            hand.add(Card(rank: rank, suit: .spades))
        }
        return hand
    }
}
