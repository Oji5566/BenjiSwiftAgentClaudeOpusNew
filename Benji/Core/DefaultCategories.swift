import Foundation

/// Default category list — preserved exactly from the web app so existing
/// users see familiar choices.
public enum DefaultCategories {
    public static let all: [String] = [
        "🍫 Snacks",
        "☕ Coffee",
        "🍽️ Dining",
        "🛍️ Shopping",
        "🎮 Entertainment",
        "🚗 Transport",
        "📱 Tech",
        "💊 Health",
        "📚 Education",
        "🎁 Gifts",
        "❓ Other"
    ]

    /// The leading emoji of a category label, falling back to ❓.
    public static func emoji(of category: String) -> String {
        category.split(separator: " ", maxSplits: 1).first.map(String.init) ?? "❓"
    }
}
