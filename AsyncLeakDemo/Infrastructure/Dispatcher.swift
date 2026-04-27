import Foundation

protocol Dispatcher: Sendable {
    func run<T: Sendable>(_ work: @Sendable @escaping () throws -> T) async throws -> T
}
