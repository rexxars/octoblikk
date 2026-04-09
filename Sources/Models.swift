import Foundation

// MARK: - GitHub Search Response

struct SearchResponse: Decodable, Sendable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [SearchItem]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }
}

struct SearchItem: Decodable, Sendable, Identifiable {
    let id: Int
    let number: Int
    let title: String
    let htmlUrl: String
    let state: String
    let createdAt: Date
    let updatedAt: Date
    let closedAt: Date?
    let body: String?
    let user: GitHubUser
    let comments: Int
    let draft: Bool?
    let pullRequest: PullRequestRef?

    enum CodingKeys: String, CodingKey {
        case id, number, title, state, body, user, comments, draft
        case htmlUrl = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case closedAt = "closed_at"
        case pullRequest = "pull_request"
    }
}

struct PullRequestRef: Decodable, Sendable {
    let mergedAt: Date?

    enum CodingKeys: String, CodingKey {
        case mergedAt = "merged_at"
    }
}

struct GitHubUser: Decodable, Sendable {
    let login: String
    let avatarUrl: String

    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Reviews

struct Review: Decodable, Sendable {
    let id: Int
    let user: GitHubUser
    let state: String
    let submittedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, user, state
        case submittedAt = "submitted_at"
    }
}

// MARK: - Check Runs

struct CheckRunsResponse: Decodable, Sendable {
    let totalCount: Int
    let checkRuns: [CheckRun]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case checkRuns = "check_runs"
    }
}

struct CheckRun: Decodable, Sendable {
    let id: Int
    let name: String
    let status: String
    let conclusion: String?
}

// MARK: - Combined Commit Status

struct CombinedStatus: Decodable, Sendable {
    let state: String
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case state
        case totalCount = "total_count"
    }
}

// MARK: - PR Detail (from pulls endpoint, has mergeable info)

struct PRDetail: Decodable, Sendable {
    let mergeable: Bool?
    let mergeableState: String?
    let reviewComments: Int

    enum CodingKeys: String, CodingKey {
        case mergeable
        case mergeableState = "mergeable_state"
        case reviewComments = "review_comments"
    }
}

// MARK: - App Domain Model

enum PRStatus: String, Sendable {
    case approved
    case changesRequested
    case checksFailed
    case waitingForReview
    case merged
    case closed
    case notMergeable
    case draft
}

struct PullRequest: Identifiable, Sendable {
    let id: Int
    let number: Int
    let title: String
    let htmlUrl: String
    let repoFullName: String
    let orgName: String
    let orgAvatarUrl: String
    let status: PRStatus
    let isDraft: Bool
    let commentCount: Int
    let updatedAt: Date
    let createdAt: Date
    let closedAt: Date?
}

// MARK: - Persistence Models

struct SeenState: Codable, Sendable {
    var prs: [String: PRSeenInfo]
}

struct PRSeenInfo: Codable, Sendable {
    var lastSeenCommentCount: Int
    var archived: Bool
    var lastOpenedAt: Date?
}

struct AppSettings: Codable, Sendable {
    var pollIntervalMinutes: Int

    static let `default` = AppSettings(pollIntervalMinutes: 5)
}
