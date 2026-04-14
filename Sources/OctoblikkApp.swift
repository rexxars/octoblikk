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
            let tint = viewModel.unreadMenuBarColor
            HStack(spacing: 2) {
                if let nsImage = loadMenuBarIcon(template: tint == nil) {
                    Image(nsImage: nsImage)
                } else {
                    Image(systemName: "arrow.triangle.pull")
                }
                if viewModel.openCount > 0 {
                    Text("\(viewModel.openCount)")
                }
            }
            .foregroundStyle(tint ?? .primary)
        }
        .menuBarExtraStyle(.window)
    }

    private func loadMenuBarIcon(template: Bool) -> NSImage? {
        guard let url = Bundle.module.url(forResource: "MenuBarIcon", withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        image.isTemplate = template
        image.size = NSSize(width: 18, height: 18)
        return image
    }
}
