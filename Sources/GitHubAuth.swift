import Foundation

enum AuthError: Error, LocalizedError {
    case ghNotInstalled
    case notAuthenticated(String)

    var errorDescription: String? {
        switch self {
        case .ghNotInstalled:
            "GitHub CLI (gh) is not installed. Install it from https://cli.github.com"
        case .notAuthenticated(let detail):
            "GitHub CLI is not authenticated. Run `gh auth login` in your terminal. (\(detail))"
        }
    }
}

enum GitHubAuth {
    static func getToken() async throws(AuthError) -> String {
        guard let ghPath = locateGh() else {
            throw .ghNotInstalled
        }

        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: ghPath)
        process.arguments = ["auth", "token"]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            throw .ghNotInstalled
        }

        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0, !output.isEmpty else {
            throw .notAuthenticated(output)
        }

        return output
    }

    private static func locateGh() -> String? {
        let fm = FileManager.default
        let home = NSHomeDirectory()
        let candidates = [
            "/opt/homebrew/bin/gh",
            "/usr/local/bin/gh",
            "/usr/bin/gh",
            "\(home)/.local/bin/gh",
            "\(home)/bin/gh",
        ]
        for path in candidates where fm.isExecutableFile(atPath: path) {
            return path
        }
        return locateGhViaLoginShell()
    }

    private static func locateGhViaLoginShell() -> String? {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-lc", "command -v gh"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard process.terminationStatus == 0, !path.isEmpty, FileManager.default.isExecutableFile(atPath: path) else {
            return nil
        }
        return path
    }
}
