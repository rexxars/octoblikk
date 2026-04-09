# Octoblikk

A macOS menu bar app that shows your GitHub pull requests at a glance.

Open PRs, recently merged ones, drafts - all in a popover, sorted by activity. Background colors tell you the status without reading a word. Bold titles and a dot tell you something happened since you last looked.

![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange) ![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue) ![License: MIT](https://img.shields.io/badge/License-MIT-green)

## What it does

- Shows all your open PRs across all of GitHub
- Background color per row reflects status: green for approved, orange for changes requested, red for failed checks, purple for merged, and so on
- Tracks unread activity based on new comments (including inline review comments), with bot comments filtered out
- Merged/closed PRs stick around until you explicitly archive them - no arbitrary time cutoff
- Draft PRs get their own compact section at the bottom
- Polls GitHub on a configurable interval (default: 5 minutes)
- Click a PR to open it in your browser
- "Mark as read" per PR or "Mark all read" in one click
- Optional launch at login

## Prerequisites

- macOS 15 or later
- [GitHub CLI](https://cli.github.com) (`gh`) installed and authenticated:

```bash
brew install gh
gh auth login
```

The app runs `gh auth token` on launch to get your GitHub credentials from the CLI.

## Install

```bash
git clone git@github.com:rexxars/octoblikk.git
cd octoblikk
./install.sh
```

This builds a release binary, creates an app bundle at `~/Applications/Octoblikk.app`, and launches it. First run, macOS will ask you to right-click > Open to bypass the unsigned app warning.

To rebuild after making changes, run `./install.sh` again.

## Development

Build and run from source:

```bash
swift build
swift run octoblikk
```

Or open `Package.swift` in Xcode for the full IDE experience.

## PR status colors

| Status | Color |
|--------|-------|
| Approved | Green |
| Waiting for review | Neutral |
| Changes requested | Orange |
| Checks failed | Red |
| Merged | Purple |
| Closed | Light orange |
| Not mergeable | Gray |

## How unread tracking works

The app tracks the comment count (issue comments + review comments) for each PR. When the count increases since you last viewed a PR, it shows as unread: bold title, blue dot. Comments from bots (`dependabot`, `github-actions`, `renovate`, etc.) are filtered out.

Opening a PR in the browser or clicking "Mark as read" clears the unread state. "Mark all read" in the section header clears everything at once.

## How archiving works

When a PR gets merged or closed, it stays in the "Merged / Closed" section until you dismiss it. This way you never miss that something happened to a PR while you were away. Click the checkmark to archive individual PRs, or "Clear all" to dismiss the entire section.

## Settings

Click the gear icon in the footer:

- **Poll interval** - How often to check GitHub (1, 2, 5, 10, 15, or 30 minutes)
- **Launch at login** - Start Octoblikk when you log in

Settings and seen state are stored in `~/Library/Application Support/octoblikk/`.

## Built with

- Swift 6.2 and SwiftUI
- `MenuBarExtra` with `.window` style
- Swift Package Manager
- GitHub REST API via Foundation `URLSession`
- No external dependencies

## License

MIT
