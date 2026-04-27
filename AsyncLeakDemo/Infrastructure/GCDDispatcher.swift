import Foundation

// GCD-based execution strategy. Unlike SwiftConcurrencyDispatcher's
// Task.detached, DispatchQueue.global doesn't share Swift's cooperative
// thread pool — blocking I/O here cannot starve the concurrency runtime.
// Use this when `work` performs blocking calls (Thread.sleep, synchronous
// DB drivers, blocking C libraries, etc.).
struct GCDDispatcher: Dispatcher {
    let queue: DispatchQueue

    init(queue: DispatchQueue = .global(qos: .userInitiated)) {
        self.queue = queue
    }

    func run<T: Sendable>(_ work: @Sendable @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<T, Error>) in
            queue.async {
                do { cont.resume(returning: try work()) }
                catch { cont.resume(throwing: error) }
            }
        }
    }
}
