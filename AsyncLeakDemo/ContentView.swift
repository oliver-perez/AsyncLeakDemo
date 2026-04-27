import SwiftUI

struct ContentView: View {
    let viewModel: AddFavoriteViewModel

    var body: some View {
        AddFavoriteView(viewModel: viewModel)
    }
}
