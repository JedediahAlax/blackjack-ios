//
//  Card.swift
//  Blackjack
//
//  Created by Jedediah Hernandez on 11/5/26.
//

struct Card {
    let rank: Rank
    let suit: Suit
}

enum Suit {
    case hearts, diamonds, clubs, spades
}

enum Rank {
    case ace, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king
    
    var points: Int {
        switch self {
        case .ace: 1
        case .two: 2
        case .three: 3
        case .four: 4
        case .five: 5
        case .six: 6
        case .seven: 7
        case .eight: 8
        case .nine: 9
        case .ten, .jack, .queen, .king: 10
            
        }
    }
}
