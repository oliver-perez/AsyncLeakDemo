import Foundation

struct AddFavoriteUseCase {
    let repository: any MovieRepository

    func execute(_ rawTitle: String) throws -> MovieTitle {
        let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { throw ValidationError.tooShort }
        guard trimmed.count <= 100 else { throw ValidationError.tooLong }
        let title = MovieTitle(value: trimmed)
        try repository.save(title)
        return title
    }
}
