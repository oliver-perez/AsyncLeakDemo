import Foundation

final class InMemoryMovieRepository: MovieRepository {
    private(set) var saved: [MovieTitle] = []

    func save(_ title: MovieTitle) throws {
        Thread.sleep(forTimeInterval: 1.5)
        saved.append(title)
    }
}
