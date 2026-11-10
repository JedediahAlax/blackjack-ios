import Observation

// The engine refuses any move that isn't legal right now, so `try?` here only ignores a late tap.
@MainActor
@Observable
final class GameViewModel {
    let chipValues = [10, 50, 100]

    private(set) var game: BlackjackGame
    private(set) var pendingBet = 0
    private let dealerPause: Duration

    init(game: BlackjackGame = BlackjackGame(), dealerPause: Duration = .milliseconds(800)) {
        self.game = game
        self.dealerPause = dealerPause
    }

    // MARK: Betting

    // The chips being placed, then the bet in play once the cards are out.
    var currentBet: Int {
        game.phase == .betting ? pendingBet : game.bet
    }

    var canDeal: Bool {
        game.phase == .betting && game.isValid(bet: pendingBet)
    }

    func canAdd(chip: Int) -> Bool {
        game.phase == .betting && game.isValid(bet: pendingBet + chip)
    }

    func add(chip: Int) {
        guard canAdd(chip: chip) else { return }

        pendingBet += chip
    }

    func clearBet() {
        pendingBet = 0
    }

    func deal() {
        guard canDeal else { return }

        try? game.deal(bet: pendingBet)
        pendingBet = 0
    }

    func rebuy() {
        try? game.rebuy()
    }

    // MARK: Playing

    var isPlayersTurn: Bool {
        game.phase == .playerTurn
    }

    // Hitting to 21 ends the player's turn, so the dealer can follow a hit too.
    func hit() async {
        guard isPlayersTurn else { return }

        try? game.hit()
        await playDealerTurn()
    }

    func stand() async {
        guard isPlayersTurn else { return }

        try? game.stand()
        await playDealerTurn()
    }

    func nextRound() {
        try? game.startNextRound()
    }

    private func playDealerTurn() async {
        while game.phase == .dealerTurn {
            try? await Task.sleep(for: dealerPause)
            try? game.playDealerStep()
        }
    }

    // MARK: Display

    var isHoleCardHidden: Bool {
        isPlayersTurn
    }

    var playerTotalText: String? {
        totalText(for: game.playerHand)
    }

    var dealerTotalText: String? {
        isHoleCardHidden ? nil : totalText(for: game.dealerHand)
    }

    var resultText: String? {
        guard let outcome = game.outcome else { return nil }

        switch outcome {
        case .blackjack:
            return "Blackjack!"
        case .win:
            return game.dealerHand.isBust ? "Dealer busts. You win!" : "You win!"
        case .push:
            return "Push"
        case .lose:
            if game.playerHand.isBust { return "Bust. Dealer wins." }
            return game.dealerHand.isBlackjack ? "Dealer blackjack" : "Dealer wins"
        }
    }

    // "Soft" only matters while the total can still change, so a 21 is just 21.
    private func totalText(for hand: Hand) -> String? {
        guard !hand.cards.isEmpty else { return nil }

        return hand.isSoft && hand.total < 21 ? "Soft \(hand.total)" : "\(hand.total)"
    }
}
