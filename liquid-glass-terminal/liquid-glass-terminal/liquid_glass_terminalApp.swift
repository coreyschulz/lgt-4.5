//
//  liquid_glass_terminalApp.swift
//  liquid-glass-terminal
//
//  Created by Corey Schulz on 11/24/25.
//

import SwiftUI

@main
struct LiquidGlassTerminalApp: App {
    /// Shared glass effect settings - single source of truth
    @State private var glassSettings = GlassEffectSettings.load()

    var body: some Scene {
        // Main Terminal Window
        WindowGroup {
            MainWindowView()
                .environment(\.glassSettings, glassSettings)
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

            // Playground menu command
            CommandGroup(after: .windowArrangement) {
                Button("Show Glass Playground") {
                    NotificationCenter.default.post(name: .showPlayground, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }

        // Glass Playground Window
        Window("Glass Playground", id: "playground") {
            PlaygroundWindowView()
                .environment(\.glassSettings, glassSettings)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 420, height: 850)
        .defaultPosition(.topTrailing)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let clearTerminal = Notification.Name("clearTerminal")
    static let restartShell = Notification.Name("restartShell")
    static let showPlayground = Notification.Name("showPlayground")
}
