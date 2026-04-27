import SwiftUI

struct AddFavoriteView: View {
    @Bindable var viewModel: AddFavoriteViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Add a Favorite Movie")
                .font(.title2.bold())

            TextField("Movie title", text: $viewModel.rawTitle)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()

            Button {
                viewModel.save()
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                    }
                    Text(viewModel.isSaving ? "Saving..." : "Save")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSaving)

            Text(viewModel.status)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(minHeight: 24)

            Spacer()
        }
        .padding()
    }
}
