//
//  liquid_glass_terminalApp.swift
//  liquid-glass-terminal
//
//  Created by Corey Schulz on 11/24/25.
//

import SwiftUI

@main
struct LiquidGlassTerminalApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowBackgroundDragBehavior(.enabled)
        .defaultSize(width: 800, height: 600)
        .commands {
            // Terminal menu commands
            CommandGroup(after: .newItem) {
                Button("Clear Terminal") {
                    NotificationCenter.default.post(name: .clearTerminal, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])

                Button("Restart Shell") {
                    NotificationCenter.default.post(name: .restartShell, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let clearTerminal = Notification.Name("clearTerminal")
    static let restartShell = Notification.Name("restartShell")
}
