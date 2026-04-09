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
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["gh", "auth", "token"]
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
}
