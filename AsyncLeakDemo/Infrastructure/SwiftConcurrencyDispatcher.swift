import Foundation

// NOTE: Task.detached runs on Swift's cooperative thread pool — the same pool
// every regular Task uses. If `work` performs blocking I/O (Thread.sleep, a
// synchronous DB driver, a blocking C library), it ties up one of the pool's
// limited threads for the full duration. Enough concurrent blocking calls
// can starve the entire concurrency runtime. Stage 4 addresses this with
// a GCD-based dispatcher that doesn't share the cooperative pool.
struct SwiftConcurrencyDispatcher: Dispatcher {
    func run<T: Sendable>(_ work: @Sendable @escaping () throws -> T) async throws -> T {
        try await Task.detached(priority: .userInitiated) {
            try work()
        }.value
    }
}
