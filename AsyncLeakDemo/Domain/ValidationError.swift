import Foundation

enum ValidationError: Error, LocalizedError, Equatable {
    case tooShort
    case tooLong

    var errorDescription: String? {
        switch self {
        case .tooShort: return "Title must be at least 2 characters."
        case .tooLong:  return "Title must be at most 100 characters."
        }
    }
}
