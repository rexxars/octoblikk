import SwiftUI

struct ContentView: View {
    @Environment(PRViewModel.self) var viewModel

    var body: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Approved PRs
                    if !viewModel.approvedPRs.isEmpty {
                        HStack {
                            SectionHeader(title: "Ready to Merge", count: viewModel.approvedPRs.count)
                            Spacer()
                            if viewModel.hasUnread {
                                Button("Mark all read") {
                                    viewModel.markAllAsRead()
                                }
                                .font(.caption)
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 12)
                            }
                        }
                        ForEach(viewModel.approvedPRs) { pr in
                            PRRow(
                                pr: pr,
                                isUnread: viewModel.isUnread(pr),
                                onOpen: { viewModel.openInBrowser(pr) },
                                onMarkRead: { viewModel.markAsRead(pr) }
                            )
                            Divider()
                        }
                    }

                    // Open PRs (non-approved)
                    if !viewModel.nonApprovedOpenPRs.isEmpty {
                        HStack {
                            SectionHeader(title: "Open Pull Requests", count: viewModel.nonApprovedOpenPRs.count)
                            Spacer()
                            if viewModel.approvedPRs.isEmpty && viewModel.hasUnread {
                                Button("Mark all read") {
                                    viewModel.markAllAsRead()
                                }
                                .font(.caption)
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 12)
                            }
                        }
                        ForEach(viewModel.nonApprovedOpenPRs) { pr in
                            PRRow(
                                pr: pr,
                                isUnread: viewModel.isUnread(pr),
                                onOpen: { viewModel.openInBrowser(pr) },
                                onMarkRead: { viewModel.markAsRead(pr) }
                            )
                            Divider()
                        }
                    }

                    // Merged / Closed
                    if !viewModel.closedPRs.isEmpty {
                        HStack {
                            SectionHeader(title: "Merged / Closed", count: viewModel.closedPRs.count)
                            Spacer()
                            Button("Clear all") {
                                viewModel.archiveAll()
                            }
                            .font(.caption)
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 12)
                        }
                        ForEach(viewModel.closedPRs) { pr in
                            HStack(spacing: 0) {
                                PRRow(
                                    pr: pr,
                                    isUnread: viewModel.isUnread(pr),
                                    onOpen: { viewModel.openInBrowser(pr) },
                                    onMarkRead: { viewModel.markAsRead(pr) }
                                )
                                Button(action: { viewModel.archive(pr) }) {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Archive")
                                .padding(.trailing, 12)
                            }
                            Divider()
                        }
                    }

                    // Drafts
                    if !viewModel.draftPRs.isEmpty {
                        SectionHeader(title: "Drafts", count: viewModel.draftPRs.count)
                        ForEach(viewModel.draftPRs) { pr in
                            DraftPRRow(pr: pr, onOpen: { viewModel.openInBrowser(pr) })
                            Divider()
                        }
                    }

                    // Loading state
                    if viewModel.isLoading && viewModel.lastFetchedAt == nil {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading pull requests...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }

                    // Empty state
                    if viewModel.openPRs.isEmpty && viewModel.closedPRs.isEmpty && viewModel.draftPRs.isEmpty && !viewModel.isLoading && viewModel.errorMessage == nil {
                        Text("No pull requests found")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    }
                }
            }

            Divider()

            // Footer
            FooterView()
        }
        .frame(width: 400)
        .frame(minHeight: 200, maxHeight: 600)
        .task {
            await viewModel.start()
        }
    }
}

struct SectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
                .lineLimit(3)
            Spacer()
        }
        .padding(10)
        .background(Color.red.opacity(0.1))
    }
}

struct FooterView: View {
    @Environment(PRViewModel.self) var viewModel
    @State private var showSettings = false

    var body: some View {
        HStack {
            if viewModel.canLoadMore {
                Button("Load more") {
                    Task {
                        await viewModel.loadMoreOpen()
                        await viewModel.loadMoreClosed()
                    }
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
            }

            Spacer()

            if let lastFetch = viewModel.lastFetchedAt {
                Text("Updated \(lastFetch.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Button(action: { showSettings.toggle() }) {
                Image(systemName: "gear")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSettings) {
                SettingsView()
            }

            Button(action: {
                Task { await viewModel.refresh() }
            }) {
                Image(systemName: viewModel.isLoading ? "arrow.trianglehead.2.clockwise" : "arrow.trianglehead.clockwise")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Image(systemName: "power")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Quit Octoblikk")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
