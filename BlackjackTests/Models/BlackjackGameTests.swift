import Testing
@testable import Blackjack

struct BlackjackGameTests {

    // MARK: Dealing

    @Test func dealGoesPlayerDealerPlayerDealer() throws {
        var game = makeGame(dealing: [.two, .three, .four, .five])

        try game.deal(bet: 10)

        #expect(game.playerHand.cards.map(\.rank) == [.two, .four])
        #expect(game.dealerHand.cards.map(\.rank) == [.three, .five])
        #expect(game.phase == .playerTurn)
    }

    @Test func dealMovesTheBetOffTheBankroll() throws {
        var game = makeGame(dealing: [.two, .three, .four, .five])

        try game.deal(bet: 50)

        #expect(game.bet == 50)
        #expect(game.bankroll == 950)
    }

    @Test(arguments: [0, 5, 15, 1_010])
    func invalidBetIsRejectedAndNothingIsDealt(bet: Int) {
        var game = makeGame(dealing: [.two, .three, .four, .five])

        #expect(throws: GameError.invalidBet) {
            try game.deal(bet: bet)
        }

        #expect(game.phase == .betting)
        #expect(game.bankroll == 1_000)
        #expect(game.playerHand.cards.isEmpty)
    }

    @Test func cannotDealDuringARound() throws {
        var game = makeGame(dealing: [.two, .three, .four, .five])
        try game.deal(bet: 10)

        #expect(throws: GameError.actionNotAllowed) {
            try game.deal(bet: 10)
        }
    }

    // MARK: Blackjacks

    @Test(arguments: [
        // Player blackjack
        [Rank.ace, .five, .king, .nine],
        // Dealer blackjack, ace showing
        [.five, .ace, .nine, .king],
        // Dealer blackjack, ten-card showing
        [.five, .king, .nine, .ace],
        // Both
        [.ace, .ace, .king, .king],
    ])
    func blackjackOnTheDealEndsTheRound(ranks: [Rank]) throws {
        var game = makeGame(dealing: ranks)

        try game.deal(bet: 10)

        #expect(game.phase == .roundOver)
    }

    @Test func dealerShowingAnAceWithoutBlackjackLetsThePlayerAct() throws {
        var game = makeGame(dealing: [.five, .ace, .nine, .six])

        try game.deal(bet: 10)

        #expect(game.phase == .playerTurn)
    }

    // MARK: Player actions

    @Test func hitDealsTheNextCardToThePlayer() throws {
        var game = makeGame(dealing: [.two, .three, .four, .five, .six])
        try game.deal(bet: 10)

        try game.hit()

        #expect(game.playerHand.cards.map(\.rank) == [.two, .four, .six])
        #expect(game.dealerHand.cards.count == 2)
        #expect(game.phase == .playerTurn)
    }

    @Test func bustingEndsTheRoundWithoutTheDealerPlaying() throws {
        var game = makeGame(dealing: [.ten, .two, .nine, .three, .five])
        try game.deal(bet: 10)

        try game.hit()

        #expect(game.playerHand.isBust)
        #expect(game.phase == .roundOver)
        #expect(game.dealerHand.cards.count == 2)
    }

    @Test func hittingToTwentyOneEndsThePlayersTurn() throws {
        var game = makeGame(dealing: [.ten, .two, .six, .three, .five])
        try game.deal(bet: 10)

        try game.hit()

        #expect(game.playerHand.total == 21)
        #expect(game.phase == .dealerTurn)
    }

    @Test func standPassesTurnToTheDealerWithoutDealing() throws {
        var game = makeGame(dealing: [.ten, .two, .nine, .three])
        try game.deal(bet: 10)

        try game.stand()

        #expect(game.playerHand.cards.count == 2)
        #expect(game.phase == .dealerTurn)
    }

    @Test func playerCannotActBeforeTheDeal() {
        var game = makeGame(dealing: [])

        #expect(throws: GameError.actionNotAllowed) {
            try game.hit()
        }
        #expect(throws: GameError.actionNotAllowed) {
            try game.stand()
        }
    }

    @Test func playerCannotActAfterStanding() throws {
        var game = makeGame(dealing: [.ten, .two, .nine, .three, .five])
        try game.deal(bet: 10)
        try game.stand()

        #expect(throws: GameError.actionNotAllowed) {
            try game.hit()
        }
        #expect(throws: GameError.actionNotAllowed) {
            try game.stand()
        }
    }

    // MARK: Between rounds

    @Test func cannotStartTheNextRoundMidRound() throws {
        var game = makeGame(dealing: [.two, .three, .four, .five])
        try game.deal(bet: 10)

        #expect(throws: GameError.actionNotAllowed) {
            try game.startNextRound()
        }
    }

    @Test func startNextRoundClearsTheTable() throws {
        var game = makeGame(dealing: [.ten, .two, .nine, .three, .five])
        try game.deal(bet: 10)
        try game.hit()

        try game.startNextRound()

        #expect(game.phase == .betting)
        #expect(game.playerHand.cards.isEmpty)
        #expect(game.dealerHand.cards.isEmpty)
        #expect(game.bet == 0)
    }

    @Test func nextRoundKeepsDealingFromTheSameShoeBeforeTheCutCard() throws {
        var game = makeGame(dealing: [.ten, .two, .nine, .three, .five, .four, .six, .seven, .eight])
        try game.deal(bet: 10)
        try game.hit()
        try game.startNextRound()

        try game.deal(bet: 10)

        #expect(game.playerHand.cards.map(\.rank) == [.four, .seven])
        #expect(game.dealerHand.cards.map(\.rank) == [.six, .eight])
    }

    @Test func nextRoundGetsAFreshShoeOncePastTheCutCard() throws {
        // All five stacked cards get used, so round two can only be dealt from a new shoe.
        var game = makeGame(dealing: [.ten, .two, .nine, .three, .five])
        try game.deal(bet: 10)
        try game.hit()
        try game.startNextRound()

        try game.deal(bet: 10)

        #expect(game.playerHand.cards.count == 2)
        #expect(game.dealerHand.cards.count == 2)
    }

    /// Suits don't affect the game, so every stacked card is a spade.
    private func makeGame(dealing ranks: [Rank]) -> BlackjackGame {
        let cards = ranks.map { Card(rank: $0, suit: .spades) }
        return BlackjackGame(rules: TableRules(), shoe: Shoe(cards: cards))
    }
}
