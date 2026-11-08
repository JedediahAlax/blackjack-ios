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

    // MARK: Dealer's turn

    @Test(arguments: [
        (Rank.ten, Rank.seven),
        (.ten, .nine),
        (.king, .queen),
        // Soft 17 and soft 18
        (.ace, .six),
        (.ace, .seven),
    ])
    func dealerStandsOnSeventeenOrMore(upCard: Rank, holeCard: Rank) throws {
        var game = try makeGameOnDealersTurn(dealerCards: [upCard, holeCard])

        try game.playDealerStep()

        #expect(game.dealerHand.cards.count == 2)
        #expect(game.phase == .roundOver)
    }

    @Test(arguments: [
        (Rank.ten, Rank.six),
        (.two, .three),
        // Soft 16
        (.ace, .five),
    ])
    func dealerDrawsOneCardPerStepOnSixteenOrLess(upCard: Rank, holeCard: Rank) throws {
        var game = try makeGameOnDealersTurn(dealerCards: [upCard, holeCard, .four])

        try game.playDealerStep()

        #expect(game.dealerHand.cards.map(\.rank) == [upCard, holeCard, .four])
        #expect(game.phase == .dealerTurn)
    }

    @Test func dealerKeepsDrawingUntilReachingSeventeen() throws {
        // 2 + 3 + 4 + 5 + 3 = 17, so the nine stays in the shoe.
        var game = try makeGameOnDealersTurn(dealerCards: [.two, .three, .four, .five, .three, .nine])

        try playOutDealersTurn(&game)

        #expect(game.dealerHand.cards.map(\.rank) == [.two, .three, .four, .five, .three])
        #expect(game.dealerHand.total == 17)
        #expect(game.phase == .roundOver)
    }

    @Test func dealerStandsWhenAnAceCountedAsElevenReachesSeventeen() throws {
        // 3 + 3 + A is a soft 17, so the nine stays in the shoe.
        var game = try makeGameOnDealersTurn(dealerCards: [.three, .three, .ace, .nine])

        try playOutDealersTurn(&game)

        #expect(game.dealerHand.cards.map(\.rank) == [.three, .three, .ace])
        #expect(game.dealerHand.total == 17)
    }

    @Test func dealerKeepsDrawingWhenAnAceHasToDropBackToOne() throws {
        // Soft 16, then the king makes it a hard 16, so the dealer must draw again.
        var game = try makeGameOnDealersTurn(dealerCards: [.ace, .five, .king, .two])

        try playOutDealersTurn(&game)

        #expect(game.dealerHand.cards.map(\.rank) == [.ace, .five, .king, .two])
        #expect(game.dealerHand.total == 18)
    }

    @Test func dealerBustingEndsTheRound() throws {
        var game = try makeGameOnDealersTurn(dealerCards: [.ten, .six, .king])

        try playOutDealersTurn(&game)

        #expect(game.dealerHand.isBust)
        #expect(game.phase == .roundOver)
    }

    @Test func dealerHitsSoftSeventeenWhenTheTableRuleIsOn() throws {
        var game = try makeGameOnDealersTurn(
            dealerCards: [.ace, .six, .four],
            rules: TableRules(dealerHitsSoft17: true)
        )

        try playOutDealersTurn(&game)

        #expect(game.dealerHand.cards.map(\.rank) == [.ace, .six, .four])
        #expect(game.dealerHand.total == 21)
    }

    @Test func dealerStandsOnHardSeventeenWhenTheTableRuleIsOn() throws {
        var game = try makeGameOnDealersTurn(
            dealerCards: [.ten, .seven, .four],
            rules: TableRules(dealerHitsSoft17: true)
        )

        try playOutDealersTurn(&game)

        #expect(game.dealerHand.cards.map(\.rank) == [.ten, .seven])
    }

    @Test func dealerCannotPlayBeforeThePlayerFinishes() throws {
        var game = makeGame(dealing: [.ten, .two, .nine, .three])

        #expect(throws: GameError.actionNotAllowed) {
            try game.playDealerStep()
        }

        try game.deal(bet: 10)

        #expect(throws: GameError.actionNotAllowed) {
            try game.playDealerStep()
        }
    }

    @Test func dealerCannotPlayOnceTheRoundIsOver() throws {
        var game = try makeGameOnDealersTurn(dealerCards: [.ten, .seven])
        try game.playDealerStep()

        #expect(throws: GameError.actionNotAllowed) {
            try game.playDealerStep()
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
    private func makeGame(dealing ranks: [Rank], rules: TableRules = TableRules()) -> BlackjackGame {
        let cards = ranks.map { Card(rank: $0, suit: .spades) }
        return BlackjackGame(rules: rules, shoe: Shoe(cards: cards))
    }

    /// The player stands on 20. The first two `dealerCards` are the dealer's hand, the rest are drawn in order.
    private func makeGameOnDealersTurn(dealerCards: [Rank], rules: TableRules = TableRules()) throws -> BlackjackGame {
        let stack = [.king, dealerCards[0], .queen, dealerCards[1]] + dealerCards.dropFirst(2)
        var game = makeGame(dealing: stack, rules: rules)
        try game.deal(bet: 10)
        try game.stand()
        return game
    }

    private func playOutDealersTurn(_ game: inout BlackjackGame) throws {
        while game.phase == .dealerTurn {
            try game.playDealerStep()
        }
    }
}
