import SwiftUI

@main
struct AsyncLeakDemoApp: App {
    @State private var viewModel = AddFavoriteViewModel(
        useCase: AddFavoriteUseCase(repository: InMemoryMovieRepository())
    )

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
