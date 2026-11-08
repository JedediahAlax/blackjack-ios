enum GameError: Error, Equatable {
    case actionNotAllowed
    case invalidBet
}

struct BlackjackGame {
    enum Phase {
        case betting, playerTurn, dealerTurn, roundOver
    }

    let rules: TableRules
    private(set) var phase = Phase.betting
    private(set) var playerHand = Hand()
    private(set) var dealerHand = Hand()
    private(set) var bankroll: Int
    private(set) var bet = 0
    private var shoe: Shoe

    init(rules: TableRules = TableRules()) {
        self.init(rules: rules, shoe: Shoe(deckCount: rules.deckCount))
    }

    // Tests pass a stacked shoe to control exactly which cards are dealt.
    init(rules: TableRules, shoe: Shoe) {
        self.rules = rules
        self.shoe = shoe
        bankroll = rules.startingBankroll
    }

    mutating func deal(bet: Int) throws {
        guard phase == .betting else { throw GameError.actionNotAllowed }
        guard isValid(bet: bet) else { throw GameError.invalidBet }

        self.bet = bet
        bankroll -= bet

        // Player, dealer face up, player, dealer face down.
        playerHand.add(shoe.draw())
        dealerHand.add(shoe.draw())
        playerHand.add(shoe.draw())
        dealerHand.add(shoe.draw())

        // A dealer blackjack always has an ace or ten-card showing, so this
        // covers the dealer checking the hole card before the player acts.
        phase = playerHand.isBlackjack || dealerHand.isBlackjack ? .roundOver : .playerTurn
    }

    mutating func hit() throws {
        guard phase == .playerTurn else { throw GameError.actionNotAllowed }

        playerHand.add(shoe.draw())

        if playerHand.isBust {
            phase = .roundOver
        } else if playerHand.total == 21 {
            phase = .dealerTurn
        }
    }

    mutating func stand() throws {
        guard phase == .playerTurn else { throw GameError.actionNotAllowed }

        phase = .dealerTurn
    }

    // One decision per call, hit or stand, so the view model can pause between them.
    mutating func playDealerStep() throws {
        guard phase == .dealerTurn else { throw GameError.actionNotAllowed }

        if dealerMustHit {
            dealerHand.add(shoe.draw())
        } else {
            phase = .roundOver
        }
    }

    mutating func startNextRound() throws {
        guard phase == .roundOver else { throw GameError.actionNotAllowed }

        playerHand = Hand()
        dealerHand = Hand()
        bet = 0
        phase = .betting

        if shoe.needsReshuffle {
            shoe = Shoe(deckCount: rules.deckCount)
        }
    }

    // Soft 17 is the one total that depends on the table's rules.
    private var dealerMustHit: Bool {
        if dealerHand.total == 17 && dealerHand.isSoft {
            return rules.dealerHitsSoft17
        }
        return dealerHand.total < 17
    }

    // Bets come in whole chips of the table minimum, so a 3:2 payout is always whole dollars.
    private func isValid(bet: Int) -> Bool {
        bet >= rules.minimumBet && bet <= bankroll && bet.isMultiple(of: rules.minimumBet)
    }
}
