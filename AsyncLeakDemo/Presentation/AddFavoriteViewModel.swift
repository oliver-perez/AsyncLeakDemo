import Foundation
import Observation

@Observable
@MainActor
final class AddFavoriteViewModel {
    var rawTitle: String = ""
    var status: String = ""
    var isSaving: Bool = false

    private let useCase: AddFavoriteUseCase

    init(useCase: AddFavoriteUseCase) {
        self.useCase = useCase
    }

    func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let title = try await useCase.execute(rawTitle)
            status = "Saved: \(title.value)"
        } catch {
            status = error.localizedDescription
        }
    }
}
