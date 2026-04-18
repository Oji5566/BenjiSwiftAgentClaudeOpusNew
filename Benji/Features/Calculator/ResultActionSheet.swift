import SwiftUI

/// Bottom sheet that shows the converted amount and offers four
/// follow-up actions. Returns the selected `Decision` (or `nil` if the
/// user dismissed / chose "no track").
struct ResultActionSheet: View {
    let amount: Double
    let minutes: Double
    let rate: Double
    let onChoose: (Decision?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text(Formatters.currency(amount))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(rate > 0 ? Formatters.minutes(minutes) : "—")
                    .font(.title3)
                    .foregroundStyle(rate > 0 ? Theme.brand : .secondary)
            }
            .padding(.top, 8)

            VStack(spacing: 12) {
                actionButton("Buy", icon: "checkmark.circle.fill", tint: .green) {
                    onChoose(.buy)
                }
                actionButton("Add to Watchlist", icon: "eye.fill", tint: Theme.brand) {
                    onChoose(.watchlist)
                }
                actionButton("Skip", icon: "xmark.circle.fill", tint: .red) {
                    onChoose(.skip)
                }
                Button("Don't Track") { onChoose(nil) }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .padding(.top)
        .padding(.bottom, 24)
        .presentationBackground(.regularMaterial)
    }

    private func actionButton(_ title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }
}
