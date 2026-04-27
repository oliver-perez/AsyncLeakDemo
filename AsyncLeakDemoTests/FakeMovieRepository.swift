import Foundation
@testable import AsyncLeakDemo

final class FakeMovieRepository: MovieRepository {
    private(set) var saved: [MovieTitle] = []

    func save(_ title: MovieTitle) throws {
        saved.append(title)
    }
}
