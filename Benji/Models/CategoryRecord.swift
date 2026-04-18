import Foundation
import SwiftData

@Model
final class CategoryRecord {
    var name: String
    var sortIndex: Int
    var owner: UserAccount?

    init(name: String, sortIndex: Int, owner: UserAccount? = nil) {
        self.name = name
        self.sortIndex = sortIndex
        self.owner = owner
    }
}
