import Foundation
@testable import AsyncLeakDemo

actor FakeMovieRepository: MovieRepository {
    private(set) var saved: [MovieTitle] = []

    func save(_ title: MovieTitle) async throws {
        saved.append(title)
    }
}
