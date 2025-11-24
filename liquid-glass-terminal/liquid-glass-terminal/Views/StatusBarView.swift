//
//  StatusBarView.swift
//  liquid-glass-terminal
//
//  Bottom status bar with glass-styled pills showing terminal info.
//

import SwiftUI

/// Status bar showing shell status and terminal dimensions
struct StatusBarView: View {
    var state: TerminalState

    var body: some View {
        HStack(spacing: 12) {
            // Shell status indicator
            ShellStatusPill(
                isRunning: state.isRunning,
                shellName: state.shellName
            )

            Spacer()

            // Action buttons (moved from toolbar)
            ActionButtonsPill(state: state)

            // Terminal dimensions
            DimensionsPill(
                rows: state.rows,
                columns: state.columns
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        // No background - let parent's glass show through
    }
}

/// Pill showing shell running status
struct ShellStatusPill: View {
    let isRunning: Bool
    let shellName: String

    var body: some View {
        HStack(spacing: 6) {
            // Status indicator dot
            Circle()
                .fill(isRunning ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .shadow(color: isRunning ? .green.opacity(0.5) : .red.opacity(0.5), radius: 4)

            // Shell name
            Text(shellName)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .glassEffect(.regular, in: Capsule())
    }
}

/// Pill showing terminal dimensions
struct DimensionsPill: View {
    let rows: Int
    let columns: Int

    var body: some View {
        Text("\(columns)×\(rows)")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .glassEffect(.regular, in: Capsule())
    }
}

/// Pill with action buttons (Clear and Restart)
struct ActionButtonsPill: View {
    var state: TerminalState

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { state.clear() }) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Clear terminal (⌘K)")

            Button(action: { state.restart() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Restart shell (⇧⌘R)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .glassEffect(.regular, in: Capsule())
    }
}

#Preview {
    VStack {
        Spacer()
        StatusBarView(state: TerminalState())
    }
    .frame(width: 600, height: 100)
    .background(Color.black.opacity(0.3))
}
