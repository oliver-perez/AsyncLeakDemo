import Foundation

protocol MovieRepository {
    func save(_ title: MovieTitle) throws
}
