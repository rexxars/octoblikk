import SwiftUI

struct PRRow: View {
    let pr: PullRequest
    let isUnread: Bool
    let onOpen: () -> Void
    let onMarkRead: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 8) {
                // Unread dot
                Circle()
                    .fill(isUnread ? Color.accentColor : Color.clear)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                // Org avatar
                AsyncImage(url: URL(string: pr.orgAvatarUrl)) { image in
                    image.resizable()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 20, height: 20)
                .clipShape(Circle())
                .padding(.top, 2)

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(pr.repoFullName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(pr.title)
                        .font(.body)
                        .fontWeight(isUnread ? .bold : .regular)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                }

                Spacer()

                // Mark as read button
                if isUnread {
                    Button(action: onMarkRead) {
                        Image(systemName: "eye")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Mark as read")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(pr.status.backgroundColor)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(pr.status.label)
    }
}

struct DraftPRRow: View {
    let pr: PullRequest
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: pr.orgAvatarUrl)) { image in
                    image.resizable()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 16, height: 16)
                .clipShape(Circle())

                Text(pr.repoFullName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Text(pr.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
