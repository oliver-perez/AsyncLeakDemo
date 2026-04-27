import Foundation

struct AddFavoriteUseCase: Sendable {
    let repository: any MovieRepository

    // What inside this function actually needs to suspend?
    // Trimming a string? A length check? Nothing here is async by nature.
    // The `async` keyword is here purely because `repository.save` demands it.
    func execute(_ rawTitle: String) async throws -> MovieTitle {
        let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { throw ValidationError.tooShort }
        guard trimmed.count <= 100 else { throw ValidationError.tooLong }
        let title = MovieTitle(value: trimmed)
        try await repository.save(title)
        return title
    }
}
