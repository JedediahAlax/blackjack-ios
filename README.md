# Blackjack

A native iOS Blackjack game built with Swift and SwiftUI.

## Requirements

- Xcode 26 or later
- iOS 18 or later, iPhone in portrait

There are no third-party dependencies.

## Build and run

1. Open `Blackjack.xcodeproj` in Xcode.
2. Select the `Blackjack` scheme and any iPhone simulator.
3. Press ⌘R to run the app, or ⌘U to run the tests.

To run the tests from the command line:

```bash
xcodebuild test -project Blackjack.xcodeproj -scheme Blackjack \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Replace `iPhone 17` with any simulator listed by `xcrun simctl list devices available`.

## How to play

Tap chips to place a bet, then tap Deal. On your turn, tap Hit or Stand. The dealer then plays out their hand, the round is settled, and Next Hand starts a new one.

## Rules

The rules follow the [Bicycle Cards page](https://bicyclecards.com/how-to-play/blackjack/) linked in the assignment. Where it doesn't say, such as the deal order and when the dealer checks for blackjack, I used Bicycle's detailed rules, which are standard casino rules.

- Cards are dealt to the player, the dealer face up, the player, then the dealer face down.
- Face cards count 10. Aces count 1 or 11, whichever is better without going over 21.
- A blackjack (an Ace and a 10-value card as the first two cards) pays 3:2. If either side has one, the round ends right after the deal. Two blackjacks push.
- Going over 21 loses right away, even if the dealer would also have busted.
- Hitting to 21 ends your turn automatically.
- The dealer hits on 16 or less and stands on 17 or more, including a soft 17.
- A win pays 1:1 and a tie is a push, so the bet is returned.

## Features beyond the core game

- Betting with a $1,000 bankroll, $10, $50 and $100 chips, and a $10 minimum bet.
- A rebuy when the bankroll drops below the minimum bet.
- A two-deck shoe that reshuffles between rounds once fewer than a quarter of its cards are left.
- Table settings in `TableRules.swift`: the number of decks (1 to 8), the minimum bet, the starting bankroll, and whether the dealer hits soft 17.
- The dealer's turn plays one card at a time.
- Unit tests for the game engine and view model, written with Swift Testing.

Not included: splitting, doubling down, insurance and multiplayer.

## Project structure

The app uses MVVM on top of a plain Swift game engine.

- `Models/` holds `Card`, `Hand`, `Shoe`, `TableRules` and `BlackjackGame`. They're value types with no UI code. `BlackjackGame` moves through four phases (betting, the player's turn, the dealer's turn, round over) and throws if an action isn't allowed in the current phase.
- `ViewModels/GameViewModel.swift` turns game state into what the screen shows, holds the bet while chips are placed, and paces the dealer's turn.
- `Views/` holds `GameView`, `HandView` and `CardView`, which contain no game logic.
- `BlackjackTests/` mirrors the app folders. Tests deal from a stacked shoe, so every hand is predictable.
