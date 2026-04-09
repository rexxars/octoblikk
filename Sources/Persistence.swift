import Foundation

enum Persistence {
    private static var appSupportDir: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("octoblikk", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Seen State

    static func loadSeenState() -> SeenState {
        let url = appSupportDir.appendingPathComponent("seen_state.json")
        guard let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(SeenState.self, from: data) else {
            return SeenState(prs: [:])
        }
        return state
    }

    static func saveSeenState(_ state: SeenState) {
        let url = appSupportDir.appendingPathComponent("seen_state.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Settings

    static func loadSettings() -> AppSettings {
        let url = appSupportDir.appendingPathComponent("settings.json")
        guard let data = try? Data(contentsOf: url),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    static func saveSettings(_ settings: AppSettings) {
        let url = appSupportDir.appendingPathComponent("settings.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(settings) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
