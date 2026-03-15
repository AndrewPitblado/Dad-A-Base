import Foundation
import SwiftData

@Model
final class FavoriteJoke {
    @Attribute(.unique) var text: String
    var dateAdded: Date

    init(text: String, dateAdded: Date = .now) {
        self.text = text
        self.dateAdded = dateAdded
    }
}
