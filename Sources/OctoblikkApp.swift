import SwiftUI

@main
struct OctoblikkApp: App {
    @State private var viewModel = PRViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(viewModel)
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "arrow.triangle.pull")
                if viewModel.openCount > 0 {
                    Text("\(viewModel.openCount)")
                }
                if viewModel.hasUnread {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
