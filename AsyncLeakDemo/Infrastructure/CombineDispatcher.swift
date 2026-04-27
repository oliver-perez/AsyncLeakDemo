import Combine
import Foundation

// Combine-based execution strategy. Wraps the work in a `Future`, runs it on
// the supplied queue, and bridges the resulting publisher back to async/await
// through a checked continuation.
//
// In practice this dispatcher is more ceremony than `GCDDispatcher` for the
// same outcome — Combine's value here is when the call site wants to stay in
// the publisher world (e.g. composing with other publishers). Included for
// completeness: the `Dispatcher` port doesn't care which mechanism delivers
// the result, so a Combine-shaped one plugs in unchanged.
struct CombineDispatcher: Dispatcher {
    let queue: DispatchQueue

    init(queue: DispatchQueue = .global(qos: .userInitiated)) {
        self.queue = queue
    }

    func run<T: Sendable>(_ work: @Sendable @escaping () throws -> T) async throws -> T {
        let publisher = Future<T, Error> { promise in
            self.queue.async {
                promise(Result { try work() })
            }
        }

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<T, Error>) in
            var cancellable: AnyCancellable?
            cancellable = publisher.sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        cont.resume(throwing: error)
                    }
                    _ = cancellable // keep the subscription alive until completion
                },
                receiveValue: { value in
                    cont.resume(returning: value)
                }
            )
        }
    }
}
