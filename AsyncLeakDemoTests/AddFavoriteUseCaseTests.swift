import Testing
@testable import AsyncLeakDemo

struct AddFavoriteUseCaseTests {

    @Test func savesValidTitle() throws {
        let repo = FakeMovieRepository()
        let useCase = AddFavoriteUseCase(repository: repo)

        let title = try useCase.execute("Inception")

        #expect(title.value == "Inception")
        #expect(repo.saved == [title])
    }

    @Test func trimsWhitespace() throws {
        let repo = FakeMovieRepository()
        let useCase = AddFavoriteUseCase(repository: repo)

        let title = try useCase.execute("  Dune  ")

        #expect(title.value == "Dune")
    }

    @Test func rejectsTooShort() {
        let repo = FakeMovieRepository()
        let useCase = AddFavoriteUseCase(repository: repo)

        #expect(throws: ValidationError.tooShort) {
            try useCase.execute("I")
        }
        #expect(repo.saved.isEmpty)
    }

    @Test func rejectsTooLong() {
        let repo = FakeMovieRepository()
        let useCase = AddFavoriteUseCase(repository: repo)
        let longTitle = String(repeating: "A", count: 101)

        #expect(throws: ValidationError.tooLong) {
            try useCase.execute(longTitle)
        }
    }
}
