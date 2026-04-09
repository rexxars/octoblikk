import Foundation

enum GitHubError: Error, LocalizedError {
    case httpError(Int, String)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let message):
            "GitHub API error (\(code)): \(message)"
        case .networkError(let error):
            "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            "Failed to parse response: \(error.localizedDescription)"
        }
    }
}

actor GitHubService {
    private let token: String
    private let session: URLSession
    private let decoder: JSONDecoder

    init(token: String) {
        self.token = token
        self.session = URLSession.shared

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Search PRs

    func fetchOpenPRs(page: Int = 1, perPage: Int = 30) async throws -> SearchResponse {
        let query = "is:pr author:@me is:open"
        return try await searchIssues(query: query, sort: "updated", page: page, perPage: perPage)
    }

    func fetchClosedPRs(page: Int = 1, perPage: Int = 30) async throws -> SearchResponse {
        let query = "is:pr author:@me is:closed"
        return try await searchIssues(query: query, sort: "updated", page: page, perPage: perPage)
    }

    private func searchIssues(query: String, sort: String, page: Int, perPage: Int) async throws -> SearchResponse {
        var components = URLComponents(string: "https://api.github.com/search/issues")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "sort", value: sort),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page)),
        ]
        return try await request(url: components.url!)
    }

    // MARK: - Reviews

    func fetchReviews(owner: String, repo: String, prNumber: Int) async throws -> [Review] {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/pulls/\(prNumber)/reviews")!
        return try await request(url: url)
    }

    // MARK: - Check Runs

    func fetchCheckRuns(owner: String, repo: String, ref: String) async throws -> CheckRunsResponse {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/commits/\(ref)/check-runs")!
        return try await request(url: url)
    }

    // MARK: - PR Detail (for mergeable status and review comment count)

    func fetchPRDetail(owner: String, repo: String, prNumber: Int) async throws -> PRDetail {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/pulls/\(prNumber)")!
        return try await request(url: url)
    }

    // MARK: - Combined Status

    func fetchCombinedStatus(owner: String, repo: String, ref: String) async throws -> CombinedStatus {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/commits/\(ref)/status")!
        return try await request(url: url)
    }

    // MARK: - HTTP

    private func request<T: Decodable>(url: URL) async throws -> T {
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw GitHubError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            throw GitHubError.httpError(http.statusCode, body)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw GitHubError.decodingError(error)
        }
    }
}
