import SwiftUI

struct GameView: View {
    @State private var viewModel = GameViewModel()

    private let feltGreen = Color(red: 0.04, green: 0.33, blue: 0.2)
    private let gold = Color(red: 0.96, green: 0.78, blue: 0.32)

    var body: some View {
        VStack(spacing: 0) {
            header

            Spacer(minLength: 12)

            HandView(
                title: "Dealer",
                cards: viewModel.game.dealerHand.cards,
                totalText: viewModel.dealerTotalText,
                hidesHoleCard: viewModel.isHoleCardHidden
            )

            Text(viewModel.resultText ?? " ")
                .font(.title2.bold())
                .frame(height: 64)

            HandView(
                title: "You",
                cards: viewModel.game.playerHand.cards,
                totalText: viewModel.playerTotalText
            )

            Spacer(minLength: 12)

            controls
                .frame(height: 150)
        }
        .padding()
        .foregroundStyle(.white)
        .background(feltGreen.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            moneyLabel("Bankroll", amount: viewModel.game.bankroll, alignment: .leading)
            Spacer()
            moneyLabel("Bet", amount: viewModel.currentBet, alignment: .trailing)
        }
    }

    private func moneyLabel(_ title: String, amount: Int, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.caption)
            Text("$\(amount.formatted())")
                .font(.title3.bold().monospacedDigit())
        }
        .accessibilityElement(children: .combine)
    }

    // One set of controls per phase, so the only buttons on screen are legal moves.
    @ViewBuilder
    private var controls: some View {
        switch viewModel.game.phase {
        case .betting:
            bettingControls
        case .playerTurn:
            HStack(spacing: 12) {
                actionButton("Hit", tint: gold) {
                    Task { await viewModel.hit() }
                }
                actionButton("Stand", tint: .white) {
                    Task { await viewModel.stand() }
                }
            }
        case .dealerTurn:
            Text("Dealer's turn")
                .font(.headline)
        case .roundOver:
            actionButton("Next Hand", tint: gold) {
                viewModel.nextRound()
            }
        }
    }

    private var bettingControls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 18) {
                ForEach(viewModel.chipValues, id: \.self) { value in
                    chipButton(value)
                }
            }

            HStack(spacing: 12) {
                actionButton("Clear", tint: .white) {
                    viewModel.clearBet()
                }
                .disabled(viewModel.pendingBet == 0)

                actionButton("Deal", tint: gold) {
                    viewModel.deal()
                }
                .disabled(!viewModel.canDeal)
            }
        }
    }

    private func chipButton(_ value: Int) -> some View {
        let isEnabled = viewModel.canAdd(chip: value)

        return Button {
            viewModel.add(chip: value)
        } label: {
            Text("$\(value)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(chipColor(value), in: .circle)
                .overlay {
                    Circle()
                        .inset(by: 5)
                        .stroke(.white.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
    }

    private func chipColor(_ value: Int) -> Color {
        switch value {
        case 10: .blue
        case 50: .red
        default: .black
        }
    }

    private func actionButton(_ title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(tint)
    }
}

#Preview {
    GameView()
}
