import SwiftUI
import AppKit

@main
struct OctoblikkApp: App {
    @State private var viewModel = PRViewModel()

    init() {
        let vm = viewModel
        Task { await vm.start() }
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(viewModel)
        } label: {
            HStack(spacing: 2) {
                if let nsImage = loadMenuBarIcon() {
                    Image(nsImage: nsImage)
                } else {
                    Image(systemName: "arrow.triangle.pull")
                }
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

    private func loadMenuBarIcon() -> NSImage? {
        guard let url = Bundle.module.url(forResource: "MenuBarIcon", withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }
}
