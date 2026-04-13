import Foundation
import Observation
import AppKit

private let botSuffixes = ["[bot]"]
private let botLogins: Set<String> = [
    "github-actions", "vercel", "netlify", "renovate", "dependabot",
    "codecov", "sonarcloud", "mergify", "stale", "allcontributors",
]

@Observable
@MainActor
final class PRViewModel {
    // MARK: - Published state

    var openPRs: [PullRequest] = []
    var closedPRs: [PullRequest] = []
    var draftPRs: [PullRequest] = []
    var errorMessage: String?
    var lastFetchedAt: Date?
    var isLoading = false

    // MARK: - Settings

    var settings: AppSettings {
        didSet { Persistence.saveSettings(settings) }
    }

    // MARK: - Private state

    private var seenState: SeenState
    private var service: GitHubService?
    private var pollTimer: Timer?
    private var hasStarted = false
    private var openPage = 1
    private var closedPage = 1
    private var hasMoreOpen = false
    private var hasMoreClosed = false

    // MARK: - Computed

    var openCount: Int { openPRs.count }

    var approvedPRs: [PullRequest] { openPRs.filter { $0.status == .approved } }
    var nonApprovedOpenPRs: [PullRequest] { openPRs.filter { $0.status != .approved } }

    var hasUnread: Bool {
        (openPRs + closedPRs).contains { isUnread($0) }
    }

    init() {
        self.seenState = Persistence.loadSeenState()
        self.settings = Persistence.loadSettings()
    }

    // MARK: - Auth & Start

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        do {
            let token = try await GitHubAuth.getToken()
            self.service = GitHubService(token: token)
            self.errorMessage = nil
            await refresh()
            startPolling()
        } catch {
            self.errorMessage = error.localizedDescription
            hasStarted = false
        }
    }

    // MARK: - Polling

    func startPolling() {
        pollTimer?.invalidate()
        let interval = TimeInterval(settings.pollIntervalMinutes * 60)
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.refresh()
            }
        }
    }

    // MARK: - Fetching

    func refresh() async {
        guard let service else { return }
        isLoading = true
        defer { isLoading = false }

        openPage = 1
        closedPage = 1

        do {
            async let openResponse = service.fetchOpenPRs(page: 1)
            async let closedResponse = service.fetchClosedPRs(page: 1)

            let openResult = try await openResponse
            let closedResult = try await closedResponse

            hasMoreOpen = openResult.items.count == 30
            hasMoreClosed = closedResult.items.count == 30

            let allOpen = await buildPRs(from: openResult.items, isClosed: false)
            let allClosed = await buildPRs(from: closedResult.items, isClosed: true)

            self.draftPRs = allOpen.filter(\.isDraft).sorted { $0.updatedAt > $1.updatedAt }
            self.openPRs = allOpen.filter { !$0.isDraft }.sorted { $0.updatedAt > $1.updatedAt }

            // Only show closed PRs that haven't been archived
            self.closedPRs = allClosed
                .filter { !isArchived($0) }
                .sorted { $0.updatedAt > $1.updatedAt }

            self.lastFetchedAt = Date()
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func loadMoreOpen() async {
        guard let service, hasMoreOpen else { return }
        openPage += 1
        do {
            let response = try await service.fetchOpenPRs(page: openPage)
            hasMoreOpen = response.items.count == 30
            let more = await buildPRs(from: response.items, isClosed: false)
            draftPRs += more.filter(\.isDraft).sorted { $0.updatedAt > $1.updatedAt }
            openPRs += more.filter { !$0.isDraft }.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func loadMoreClosed() async {
        guard let service, hasMoreClosed else { return }
        closedPage += 1
        do {
            let response = try await service.fetchClosedPRs(page: closedPage)
            hasMoreClosed = response.items.count == 30
            let more = await buildPRs(from: response.items, isClosed: true)
            closedPRs += more.filter { !isArchived($0) }.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    var canLoadMore: Bool { hasMoreOpen || hasMoreClosed }

    // MARK: - Unread

    func isUnread(_ pr: PullRequest) -> Bool {
        let key = prKey(pr)
        guard let seen = seenState.prs[key] else { return pr.commentCount > 0 }
        return pr.commentCount > seen.lastSeenCommentCount
    }

    func markAsRead(_ pr: PullRequest) {
        let key = prKey(pr)
        var info = seenState.prs[key] ?? PRSeenInfo(lastSeenCommentCount: 0, archived: false)
        info.lastSeenCommentCount = pr.commentCount
        info.lastOpenedAt = Date()
        seenState.prs[key] = info
        Persistence.saveSeenState(seenState)
    }

    func markAllAsRead() {
        for pr in openPRs + closedPRs + draftPRs {
            let key = prKey(pr)
            var info = seenState.prs[key] ?? PRSeenInfo(lastSeenCommentCount: 0, archived: false)
            info.lastSeenCommentCount = pr.commentCount
            seenState.prs[key] = info
        }
        Persistence.saveSeenState(seenState)
    }

    func openInBrowser(_ pr: PullRequest) {
        markAsRead(pr)
        if let url = URL(string: pr.htmlUrl) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Archive

    func isArchived(_ pr: PullRequest) -> Bool {
        seenState.prs[prKey(pr)]?.archived ?? false
    }

    func archive(_ pr: PullRequest) {
        let key = prKey(pr)
        var info = seenState.prs[key] ?? PRSeenInfo(lastSeenCommentCount: 0, archived: false)
        info.archived = true
        seenState.prs[key] = info
        closedPRs.removeAll { $0.id == pr.id }
        Persistence.saveSeenState(seenState)
    }

    func archiveAll() {
        for pr in closedPRs {
            let key = prKey(pr)
            var info = seenState.prs[key] ?? PRSeenInfo(lastSeenCommentCount: 0, archived: false)
            info.archived = true
            seenState.prs[key] = info
        }
        closedPRs.removeAll()
        Persistence.saveSeenState(seenState)
    }

    // MARK: - Helpers

    private func prKey(_ pr: PullRequest) -> String {
        "\(pr.repoFullName)#\(pr.number)"
    }

    private func buildPRs(from items: [SearchItem], isClosed: Bool) async -> [PullRequest] {
        await withTaskGroup(of: PullRequest?.self) { group in
            for item in items {
                group.addTask {
                    await self.buildPR(from: item, isClosed: isClosed)
                }
            }
            var results: [PullRequest] = []
            for await pr in group {
                if let pr { results.append(pr) }
            }
            return results
        }
    }

    private func buildPR(from item: SearchItem, isClosed: Bool) async -> PullRequest? {
        // Extract repo info from HTML URL: https://github.com/owner/repo/pull/123
        let urlParts = item.htmlUrl.split(separator: "/")
        guard urlParts.count >= 5 else { return nil }
        let owner = String(urlParts[urlParts.count - 4])
        let repo = String(urlParts[urlParts.count - 3])
        let repoFullName = "\(owner)/\(repo)"

        let isDraft = item.draft ?? false

        // For drafts, skip detailed status checks
        if isDraft {
            return PullRequest(
                id: item.id,
                number: item.number,
                title: item.title,
                htmlUrl: item.htmlUrl,
                repoFullName: repoFullName,
                orgName: owner,
                orgAvatarUrl: "https://github.com/\(owner).png?size=32",
                status: .draft,
                isDraft: true,
                commentCount: item.comments,
                updatedAt: item.updatedAt,
                createdAt: item.createdAt,
                closedAt: item.closedAt
            )
        }

        // Determine status and get review comment count
        let status: PRStatus
        var totalCommentCount = item.comments
        if item.pullRequest?.mergedAt != nil {
            status = .merged
        } else if isClosed {
            status = .closed
        } else {
            let (openStatus, reviewComments) = await determineOpenStatus(owner: owner, repo: repo, item: item)
            status = openStatus
            totalCommentCount += reviewComments
        }

        return PullRequest(
            id: item.id,
            number: item.number,
            title: item.title,
            htmlUrl: item.htmlUrl,
            repoFullName: repoFullName,
            orgName: owner,
            orgAvatarUrl: "https://github.com/\(owner).png?size=32",
            status: status,
            isDraft: false,
            commentCount: totalCommentCount,
            updatedAt: item.updatedAt,
            createdAt: item.createdAt,
            closedAt: item.closedAt
        )
    }

    private func determineOpenStatus(owner: String, repo: String, item: SearchItem) async -> (PRStatus, Int) {
        guard let service else { return (.waitingForReview, 0) }

        // Fetch reviews, PR detail, and check runs concurrently
        async let reviewsTask = service.fetchReviews(owner: owner, repo: repo, prNumber: item.number)
        async let detailTask = service.fetchPRDetail(owner: owner, repo: repo, prNumber: item.number)

        let reviews = (try? await reviewsTask) ?? []
        let detail = try? await detailTask
        let reviewCommentCount = detail?.reviewComments ?? 0

        // Check mergeable
        if let detail, detail.mergeable == false {
            return (.notMergeable, reviewCommentCount)
        }

        // Check reviews - latest non-comment review per reviewer wins
        let latestReviews = latestReviewPerUser(reviews)
        if latestReviews.contains(where: { $0.state == "CHANGES_REQUESTED" }) {
            return (.changesRequested, reviewCommentCount)
        }
        if latestReviews.contains(where: { $0.state == "APPROVED" }) {
            return (.approved, reviewCommentCount)
        }

        // Check CI status via check runs
        if let checkRuns = try? await service.fetchCheckRuns(owner: owner, repo: repo, ref: "pull/\(item.number)/head") {
            let hasFailure = checkRuns.checkRuns.contains { run in
                run.status == "completed" && (run.conclusion == "failure" || run.conclusion == "timed_out")
            }
            if hasFailure {
                return (.checksFailed, reviewCommentCount)
            }
        }

        return (.waitingForReview, reviewCommentCount)
    }

    private func latestReviewPerUser(_ reviews: [Review]) -> [Review] {
        var latest: [String: Review] = [:]
        for review in reviews where review.state != "COMMENTED" && review.state != "PENDING" {
            let login = review.user.login
            if let existing = latest[login] {
                if let existingDate = existing.submittedAt, let newDate = review.submittedAt, newDate > existingDate {
                    latest[login] = review
                }
            } else {
                latest[login] = review
            }
        }
        return Array(latest.values)
    }
}
