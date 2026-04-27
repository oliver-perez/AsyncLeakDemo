import Foundation

// The most primitive execution strategy: hand the dispatcher a closure that
// schedules work somewhere, and let the dispatcher bridge it back to async
// through a continuation. Every other adapter in this folder could be
// expressed in terms of one of these.
//
// Useful when bridging legacy callback-based APIs, third-party SDKs, or C
// interop where the async surface you have is "we'll call you back".
struct ClosureDispatcher: Dispatcher {
    private let scheduleWork: @Sendable (@escaping @Sendable () -> Void) -> Void

    init(_ scheduleWork: @escaping @Sendable (@escaping @Sendable () -> Void) -> Void) {
        self.scheduleWork = scheduleWork
    }

    func run<T: Sendable>(_ work: @Sendable @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<T, Error>) in
            scheduleWork {
                cont.resume(with: Result { try work() })
            }
        }
    }
}

extension ClosureDispatcher {
    /// Runs work on a global concurrent queue.
    static let onGlobalQueue = ClosureDispatcher { work in
        DispatchQueue.global(qos: .userInitiated).async(execute: work)
    }

    /// Runs work on the main queue. Mostly useful in tests; in production
    /// this defeats the point of moving work off the main thread.
    static let onMainQueue = ClosureDispatcher { work in
        DispatchQueue.main.async(execute: work)
    }
}
