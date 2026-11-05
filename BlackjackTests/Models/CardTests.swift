import Testing
@testable import Blackjack

struct CardTests {

    @Test(arguments: [
        (Rank.two, 2), (.three, 3), (.four, 4), (.five, 5), (.six, 6),
        (.seven, 7), (.eight, 8), (.nine, 9), (.ten, 10),
    ])
    func numberCardsAreWorthTheirPipValue(rank: Rank, expectedPoints: Int) {
        #expect(rank.points == expectedPoints)
    }

    @Test(arguments: [Rank.jack, .queen, .king])
    func faceCardsAreWorthTen(rank: Rank) {
        #expect(rank.points == 10)
    }

    @Test func aceIsWorthOneOnItsOwn() {
        // A hand decides when one of its aces counts as 11.
        #expect(Rank.ace.points == 1)
    }
}
