//
//  SwiftTermView.swift
//  liquid-glass-terminal
//
//  NSViewRepresentable wrapper for SwiftTerm's LocalProcessTerminalView.
//  Provides a working terminal with transparent background for Liquid Glass effect.
//

import SwiftUI
import SwiftTerm
import Observation

// MARK: - Transparent Terminal View

/// LocalProcessTerminalView subclass with transparent background for glass effect
class TransparentTerminalView: LocalProcessTerminalView {
    override var isOpaque: Bool { false }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTransparency()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTransparency()
    }

    private func setupTransparency() {
        wantsLayer = true
        layer?.backgroundColor = CGColor.clear
        layer?.isOpaque = false
        // Set the native background color to clear
        nativeBackgroundColor = .clear
    }

    // Override to prevent SwiftTerm from setting layer background to black
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Reset layer background after SwiftTerm's setup
        layer?.backgroundColor = CGColor.clear
    }
}

// MARK: - Terminal State

/// Observable state for the terminal
@Observable
@MainActor
final class TerminalState {
    var isRunning: Bool = false
    var shellName: String = "zsh"
    var rows: Int = 24
    var columns: Int = 80
    var title: String = "Terminal"

    /// Actions that can be triggered from outside (e.g., StatusBarView)
    var clearAction: (@MainActor () -> Void)?
    var restartAction: (@MainActor () -> Void)?

    func clear() {
        clearAction?()
    }

    func restart() {
        restartAction?()
    }
}

/// SwiftUI wrapper for SwiftTerm's LocalProcessTerminalView
struct SwiftTermView: NSViewRepresentable {
    let font: NSFont
    var state: TerminalState

    init(font: NSFont = .monospacedSystemFont(ofSize: 14, weight: .regular),
         state: TerminalState) {
        self.font = font
        self.state = state
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(state: state)
    }

    @MainActor
    func makeNSView(context: Context) -> TransparentTerminalView {
        let terminal = TransparentTerminalView(frame: .zero)

        // Set font
        terminal.font = font

        // Set up delegate for process events
        terminal.processDelegate = context.coordinator
        context.coordinator.terminalView = terminal

        // Hook up actions to state
        let coordinator = context.coordinator
        state.clearAction = {
            coordinator.clearTerminal()
        }
        state.restartAction = {
            coordinator.restartShell()
        }

        // Start the shell process
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        state.shellName = (shell as NSString).lastPathComponent
        terminal.startProcess(executable: shell, environment: buildEnvironment())
        state.isRunning = true

        return terminal
    }

    func updateNSView(_ terminal: TransparentTerminalView, context: Context) {
        terminal.font = font
    }

    /// Build environment variables for the shell
    private func buildEnvironment() -> [String] {
        var env = ProcessInfo.processInfo.environment

        // Set TERM for proper terminal emulation
        env["TERM"] = "xterm-256color"

        // Set LANG for proper character encoding
        if env["LANG"] == nil {
            env["LANG"] = "en_US.UTF-8"
        }

        // Convert to array format expected by SwiftTerm
        return env.map { "\($0.key)=\($0.value)" }
    }

    /// Coordinator to handle terminal delegate callbacks
    @MainActor
    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        let state: TerminalState
        weak var terminalView: LocalProcessTerminalView?

        init(state: TerminalState) {
            self.state = state
        }

        nonisolated func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
            Task { @MainActor in
                self.state.columns = newCols
                self.state.rows = newRows
            }
        }

        nonisolated func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            Task { @MainActor in
                self.state.title = title
            }
        }

        nonisolated func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            // Could update state with current directory if needed
        }

        nonisolated func processTerminated(source: TerminalView, exitCode: Int32?) {
            Task { @MainActor in
                self.state.isRunning = false
            }
        }

        /// Restart the shell
        func restartShell() {
            guard let terminal = terminalView else { return }

            let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

            // Build environment
            var env = ProcessInfo.processInfo.environment
            env["TERM"] = "xterm-256color"
            if env["LANG"] == nil {
                env["LANG"] = "en_US.UTF-8"
            }
            let envArray = env.map { "\($0.key)=\($0.value)" }

            terminal.startProcess(executable: shell, environment: envArray)
            state.isRunning = true
        }

        /// Clear the terminal screen
        func clearTerminal() {
            guard let terminal = terminalView else { return }
            // Send clear screen escape sequence
            terminal.send(txt: "\u{1B}[2J\u{1B}[H")
        }
    }
}

#Preview {
    SwiftTermView(state: TerminalState())
        .frame(width: 800, height: 400)
}
