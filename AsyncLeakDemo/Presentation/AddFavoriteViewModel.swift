import Foundation
import Observation

@Observable
@MainActor
final class AddFavoriteViewModel {
    var rawTitle: String = ""
    var status: String = ""
    var isSaving: Bool = false

    private let useCase: AddFavoriteUseCase
    private let dispatcher: any Dispatcher

    init(useCase: AddFavoriteUseCase, dispatcher: any Dispatcher) {
        self.useCase = useCase
        self.dispatcher = dispatcher
    }

    func save() async {
        let raw = rawTitle
        let useCase = self.useCase
        isSaving = true
        defer { isSaving = false }
        do {
            let title = try await dispatcher.run { try useCase.execute(raw) }
            status = "Saved: \(title.value)"
        } catch {
            status = error.localizedDescription
        }
    }
}
