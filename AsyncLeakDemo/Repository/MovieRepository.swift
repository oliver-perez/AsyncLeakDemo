import Foundation

protocol MovieRepository: Sendable {
    func save(_ title: MovieTitle) async throws
}
