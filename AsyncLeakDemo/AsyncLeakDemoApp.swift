import SwiftUI

@main
struct AsyncLeakDemoApp: App {
    @State private var viewModel = AddFavoriteViewModel(
        useCase: AddFavoriteUseCase(repository: InMemoryMovieRepository()),
        dispatcher: SwiftConcurrencyDispatcher()
    )

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
