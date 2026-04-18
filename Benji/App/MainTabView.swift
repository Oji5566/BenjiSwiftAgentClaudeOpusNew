import SwiftUI

/// Native four-tab interface. Uses iOS 18+/26 `TabView` style so the bar
/// gets the Liquid-Glass treatment for free.
struct MainTabView: View {
    @State private var selection: TabID = .calculator

    enum TabID: Hashable {
        case calculator, history, watchlist, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Calculator", systemImage: "dollarsign.circle.fill", value: TabID.calculator) {
                CalculatorView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: TabID.history) {
                HistoryView()
            }
            Tab("Watchlist", systemImage: "eye.fill", value: TabID.watchlist) {
                WatchlistView()
            }
            Tab("Settings", systemImage: "gearshape.fill", value: TabID.settings) {
                SettingsView()
            }
        }
    }
}
