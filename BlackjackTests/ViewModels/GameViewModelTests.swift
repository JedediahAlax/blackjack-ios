import Testing
@testable import Blackjack

@MainActor
struct GameViewModelTests {

    // MARK: Betting

    @Test func chipsBuildUpTheBet() {
        let viewModel = makeViewModel()

        viewModel.add(chip: 10)
        viewModel.add(chip: 50)

        #expect(viewModel.pendingBet == 60)
        #expect(viewModel.currentBet == 60)
    }

    @Test func chipThatWouldPassTheBankrollIsRefused() {
        let viewModel = makeViewModel(rules: TableRules(startingBankroll: 60))
        viewModel.add(chip: 50)

        #expect(!viewModel.canAdd(chip: 50))
        #expect(viewModel.canAdd(chip: 10))

        viewModel.add(chip: 50)

        #expect(viewModel.pendingBet == 50)
    }

    @Test func clearBetEmptiesTheBet() {
        let viewModel = makeViewModel()
        viewModel.add(chip: 100)

        viewModel.clearBet()

        #expect(viewModel.pendingBet == 0)
    }

    @Test func cannotDealWithoutABet() {
        let viewModel = makeViewModel(dealing: [.two, .three, .four, .five])

        #expect(!viewModel.canDeal)

        viewModel.deal()

        #expect(viewModel.game.phase == .betting)
        #expect(viewModel.game.playerHand.cards.isEmpty)
    }

    @Test func dealStartsTheRoundWithThePendingBet() {
        let viewModel = makeViewModel(dealing: [.two, .three, .four, .five])
        viewModel.add(chip: 50)

        viewModel.deal()

        #expect(viewModel.game.phase == .playerTurn)
        #expect(viewModel.game.bet == 50)
        #expect(viewModel.game.bankroll == 950)
        #expect(viewModel.currentBet == 50)
        #expect(viewModel.pendingBet == 0)
    }

    @Test func chipsCannotBeAddedDuringARound() {
        let viewModel = dealtViewModel([.two, .three, .four, .five])

        #expect(!viewModel.canAdd(chip: 10))
    }

    // MARK: Playing

    @Test func hitKeepsThePlayerInControlBelowTwentyOne() async {
        let viewModel = dealtViewModel([.two, .three, .four, .five, .six])

        await viewModel.hit()

        #expect(viewModel.game.playerHand.cards.count == 3)
        #expect(viewModel.isPlayersTurn)
    }

    @Test func standPlaysTheDealerToTheEndOfTheRound() async {
        // The player has 20. The dealer has 2 + 3, then draws a 4 and a 9 for 18.
        let viewModel = dealtViewModel([.king, .two, .queen, .three, .four, .nine])

        await viewModel.stand()

        #expect(viewModel.game.dealerHand.cards.map(\.rank) == [.two, .three, .four, .nine])
        #expect(viewModel.game.phase == .roundOver)
        #expect(viewModel.game.bankroll == 1_010)
    }

    @Test func hittingToTwentyOnePlaysTheDealerToo() async {
        // The player makes 10 + 5 + 6 against the dealer's 18.
        let viewModel = dealtViewModel([.ten, .ten, .five, .eight, .six])

        await viewModel.hit()

        #expect(viewModel.game.phase == .roundOver)
        #expect(viewModel.game.outcome == .win)
    }

    @Test func bustingSkipsTheDealer() async {
        let viewModel = dealtViewModel([.ten, .two, .nine, .three, .five])

        await viewModel.hit()

        #expect(viewModel.game.phase == .roundOver)
        #expect(viewModel.game.dealerHand.cards.count == 2)
    }

    @Test func tapsAfterTheRoundIsOverDoNothing() async {
        let viewModel = dealtViewModel([.ten, .two, .nine, .three, .five])
        await viewModel.hit()

        await viewModel.hit()
        await viewModel.stand()

        #expect(viewModel.game.playerHand.cards.count == 3)
        #expect(viewModel.game.phase == .roundOver)
    }

    // MARK: Between rounds

    @Test func nextRoundClearsTheTable() async {
        let viewModel = dealtViewModel([.ten, .two, .nine, .three, .five])
        await viewModel.hit()

        viewModel.nextRound()

        #expect(viewModel.game.phase == .betting)
        #expect(viewModel.currentBet == 0)
        #expect(viewModel.resultText == nil)
    }

    // MARK: Display

    @Test func holeCardIsHiddenOnlyWhileThePlayerCanAct() async {
        let viewModel = makeViewModel(dealing: [.king, .ten, .queen, .eight])
        #expect(!viewModel.isHoleCardHidden)

        viewModel.add(chip: 10)
        viewModel.deal()
        #expect(viewModel.isHoleCardHidden)

        await viewModel.stand()
        #expect(!viewModel.isHoleCardHidden)
    }

    @Test func holeCardIsShownWhenABlackjackEndsTheRound() {
        let viewModel = dealtViewModel([.five, .ace, .nine, .king])

        #expect(!viewModel.isHoleCardHidden)
    }

    @Test func dealerTotalStaysHiddenWithTheHoleCard() async {
        let viewModel = dealtViewModel([.king, .ten, .queen, .eight])
        #expect(viewModel.dealerTotalText == nil)

        await viewModel.stand()

        #expect(viewModel.dealerTotalText == "18")
    }

    @Test func noTotalsBeforeTheDeal() {
        let viewModel = makeViewModel()

        #expect(viewModel.playerTotalText == nil)
        #expect(viewModel.dealerTotalText == nil)
    }

    @Test(arguments: [
        ([Rank.ace, .ten, .six, .nine], "Soft 17"),
        ([.king, .ten, .seven, .nine], "17"),
        // Blackjack
        ([.ace, .five, .king, .nine], "21"),
    ])
    func playerTotalMarksSoftHandsBelowTwentyOne(ranks: [Rank], expectedText: String) {
        #expect(dealtViewModel(ranks).playerTotalText == expectedText)
    }

    // MARK: Results

    @Test func noResultWhileTheRoundIsInPlay() {
        let viewModel = dealtViewModel([.two, .three, .four, .five])

        #expect(viewModel.resultText == nil)
    }

    @Test(arguments: [
        ([Rank.ace, .five, .king, .nine], "Blackjack!"),
        ([.ace, .ace, .king, .king], "Push"),
        ([.five, .ace, .nine, .king], "Dealer blackjack"),
    ])
    func resultTextAfterABlackjackOnTheDeal(ranks: [Rank], expectedText: String) {
        #expect(dealtViewModel(ranks).resultText == expectedText)
    }

    @Test(arguments: [
        ([Rank.king, .ten, .queen, .eight], "You win!"),
        ([.king, .ten, .eight, .nine], "Dealer wins"),
        ([.king, .ten, .eight, .eight], "Push"),
        ([.king, .ten, .queen, .six, .king], "Dealer busts. You win!"),
    ])
    func resultTextAfterStanding(ranks: [Rank], expectedText: String) async {
        let viewModel = dealtViewModel(ranks)

        await viewModel.stand()

        #expect(viewModel.resultText == expectedText)
    }

    @Test func resultTextAfterBusting() async {
        let viewModel = dealtViewModel([.ten, .two, .nine, .three, .five])

        await viewModel.hit()

        #expect(viewModel.resultText == "Bust. Dealer wins.")
    }

    /// Suits don't affect the game, so every stacked card is a spade. No dealer pause, so tests run instantly.
    private func makeViewModel(dealing ranks: [Rank] = [], rules: TableRules = TableRules()) -> GameViewModel {
        let cards = ranks.map { Card(rank: $0, suit: .spades) }
        return GameViewModel(game: BlackjackGame(rules: rules, shoe: Shoe(cards: cards)), dealerPause: .zero)
    }

    /// A view model with a $10 bet already dealt, so the first four ranks are on the table.
    private func dealtViewModel(_ ranks: [Rank]) -> GameViewModel {
        let viewModel = makeViewModel(dealing: ranks)
        viewModel.add(chip: 10)
        viewModel.deal()
        return viewModel
    }
}
