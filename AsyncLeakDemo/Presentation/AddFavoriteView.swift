import SwiftUI

struct AddFavoriteView: View {
    @Bindable var viewModel: AddFavoriteViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Add a Favorite Movie")
                .font(.title2.bold())

            MainThreadHeartbeat()

            TextField("Movie title", text: $viewModel.rawTitle)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()

            Button {
                Task { await viewModel.save() }
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

/// A continuously animating row that visibly freezes whenever the main
/// thread is blocked. The rotating icon and the millisecond timestamp
/// are both driven by `TimelineView(.animation)`, which only updates
/// when the run loop can service display refreshes — so any work that
/// blocks the main thread halts both mid-motion.
private struct MainThreadHeartbeat: View {
    var body: some View {
        TimelineView(.animation) { context in
            let seconds = context.date.timeIntervalSinceReferenceDate
            let degrees = seconds.truncatingRemainder(dividingBy: 1) * 360

            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title3)
                    .rotationEffect(.degrees(degrees))
                Text(context.date, format: .dateTime
                    .hour().minute().second()
                    .secondFraction(.fractional(2)))
                    .font(.system(.body, design: .monospaced))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
