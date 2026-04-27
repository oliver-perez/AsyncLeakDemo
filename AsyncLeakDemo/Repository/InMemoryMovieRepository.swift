import Foundation

actor InMemoryMovieRepository: MovieRepository {
    private(set) var saved: [MovieTitle] = []

    func save(_ title: MovieTitle) async throws {
        try await Task.sleep(for: .seconds(1.5))
        saved.append(title)
    }
}
