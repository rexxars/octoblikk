import SwiftUI

extension PRStatus {
    var backgroundColor: Color {
        switch self {
        case .approved: Color.green.opacity(0.12)
        case .waitingForReview: Color.primary.opacity(0.04)
        case .changesRequested: Color.orange.opacity(0.12)
        case .checksFailed: Color.red.opacity(0.12)
        case .merged: Color.purple.opacity(0.12)
        case .closed: Color.orange.opacity(0.08)
        case .notMergeable: Color.gray.opacity(0.12)
        case .draft: Color.clear
        }
    }

    /// Priority for determining menu bar tint color (higher = more urgent)
    var unreadPriority: Int {
        switch self {
        case .checksFailed: 5
        case .changesRequested: 4
        case .approved: 3
        case .merged: 2
        case .notMergeable: 1
        case .closed, .waitingForReview, .draft: 0
        }
    }

    /// Color used in the menu bar when this status has unread activity
    var menuBarColor: Color? {
        switch self {
        case .checksFailed: .red
        case .changesRequested: .orange
        case .approved: .green
        case .merged: .purple
        case .notMergeable: .gray
        case .closed, .waitingForReview, .draft: nil
        }
    }

    var label: String {
        switch self {
        case .approved: "Approved"
        case .waitingForReview: "Waiting for review"
        case .changesRequested: "Changes requested"
        case .checksFailed: "Checks failed"
        case .merged: "Merged"
        case .closed: "Closed"
        case .notMergeable: "Not mergeable"
        case .draft: "Draft"
        }
    }
}
