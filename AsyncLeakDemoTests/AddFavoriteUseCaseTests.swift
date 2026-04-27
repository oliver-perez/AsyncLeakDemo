import Testing
@testable import AsyncLeakDemo

struct AddFavoriteUseCaseTests {

    @Test func savesValidTitle() async throws {
        let repo = FakeMovieRepository()
        let useCase = AddFavoriteUseCase(repository: repo)

        let title = try await useCase.execute("Inception")

        #expect(title.value == "Inception")
        let saved = await repo.saved
        #expect(saved == [title])
    }

    @Test func trimsWhitespace() async throws {
        let repo = FakeMovieRepository()
        let useCase = AddFavoriteUseCase(repository: repo)

        let title = try await useCase.execute("  Dune  ")

        #expect(title.value == "Dune")
    }

    @Test func rejectsTooShort() async {
        let repo = FakeMovieRepository()
        let useCase = AddFavoriteUseCase(repository: repo)

        await #expect(throws: ValidationError.tooShort) {
            try await useCase.execute("I")
        }
        let saved = await repo.saved
        #expect(saved.isEmpty)
    }

    @Test func rejectsTooLong() async {
        let repo = FakeMovieRepository()
        let useCase = AddFavoriteUseCase(repository: repo)
        let longTitle = String(repeating: "A", count: 101)

        await #expect(throws: ValidationError.tooLong) {
            try await useCase.execute(longTitle)
        }
    }
}
