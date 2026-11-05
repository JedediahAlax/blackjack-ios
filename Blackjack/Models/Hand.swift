struct Hand {
    private(set) var cards: [Card] = []
    
    var total: Int {
        isSoft ? hardTotal + 10 : hardTotal
    }
    
    var isBlackjack: Bool {
        total == 21 && cards.count == 2
    }
    
    var isBust: Bool {
        total > 21
    }
    
    var isSoft: Bool {
        containsAce && hardTotal + 10 <= 21 // an Ace counted as 11 adds 10
    }
    
    private var hardTotal: Int {
        var value = 0
        for card in cards {
            value += card.rank.points
        }
        
        return value
    }
    
    private var containsAce: Bool {
        cards.contains(where: { $0.rank == .ace })
    }
    
    mutating func add(_ card: Card) {
        cards.append(card)
    }
}
