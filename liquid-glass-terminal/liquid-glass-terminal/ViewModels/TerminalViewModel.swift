//
//  TerminalViewModel.swift
//  liquid-glass-terminal
//
//  Main view model connecting PTY, parser, and views.
//

import Foundation
import SwiftUI
import Combine

/// Main view model for the terminal
@MainActor
class TerminalViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Terminal buffer containing all lines and cursor state
    @Published var buffer: TerminalBuffer

    /// Whether the shell is currently running
    @Published var isRunning: Bool = false

    /// Current shell name (e.g., "zsh")
    @Published var shellName: String = "zsh"

    /// Auto-scroll to bottom on new output
    @Published var autoScroll: Bool = true

    /// Current theme
    @Published var theme: TerminalTheme = .liquidGlass

    /// Current font configuration
    @Published var font: TerminalFont = .default

    /// Whether cursor is currently visible (for blinking)
    @Published var cursorVisible: Bool = true

    // MARK: - Computed Properties

    /// Number of rows in the terminal
    var rows: Int { buffer.rows }

    /// Number of columns in the terminal
    var columns: Int { buffer.columns }

    /// All lines for display (including scrollback)
    var displayLines: [TerminalLine] { buffer.allLines }

    /// Current cursor position
    var cursor: CursorState { buffer.cursor }

    /// Color palette from current theme
    var colorPalette: [Color] { theme.palette }

    // MARK: - Private Properties

    private let ptyManager = PTYManager()
    private var emulator: TerminalEmulator!
    private var pendingData = Data()
    private var updateDebouncer: Task<Void, Never>?
    private var cursorBlinkTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(rows: Int = 24, columns: Int = 80) {
        self.buffer = TerminalBuffer(rows: rows, columns: columns)
        self.emulator = TerminalEmulator(buffer: buffer)

        setupPTYCallbacks()
        startCursorBlink()
    }

    // MARK: - Setup

    private func setupPTYCallbacks() {
        Task {
            await ptyManager.setDataCallback { [weak self] data in
                Task { @MainActor [weak self] in
                    self?.processData(data)
                }
            }

            await ptyManager.setTerminateCallback { [weak self] exitCode in
                Task { @MainActor [weak self] in
                    self?.handleTermination(exitCode: exitCode)
                }
            }
        }
    }

    private func startCursorBlink() {
        cursorBlinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.cursorVisible.toggle()
            }
        }
    }

    // MARK: - Shell Management

    /// Start the shell process
    func startShell() {
        Task {
            do {
                let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
                shellName = (shell as NSString).lastPathComponent

                try await ptyManager.spawn(
                    shell: shell,
                    environment: [:],
                    size: (rows: UInt16(rows), cols: UInt16(columns))
                )
                isRunning = true
            } catch {
                appendSystemMessage("Failed to start shell: \(error.localizedDescription)")
            }
        }
    }

    /// Terminate the shell process
    func terminateShell() {
        Task {
            await ptyManager.terminate()
            isRunning = false
        }
    }

    /// Restart the shell
    func restartShell() {
        terminateShell()
        buffer.clear()

        // Small delay before restarting
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            startShell()
        }
    }

    // MARK: - Data Processing

    private func processData(_ data: Data) {
        pendingData.append(data)

        // Debounce updates to batch rapid output
        updateDebouncer?.cancel()
        updateDebouncer = Task {
            try? await Task.sleep(for: .milliseconds(16)) // ~60fps
            guard !Task.isCancelled else { return }
            await flushPendingData()
        }
    }

    private func flushPendingData() async {
        guard !pendingData.isEmpty else { return }

        let data = pendingData
        pendingData = Data()

        // Process through emulator (updates buffer)
        emulator.process(data)

        // Trigger SwiftUI update
        objectWillChange.send()
    }

    private func handleTermination(exitCode: Int32) {
        isRunning = false
        appendSystemMessage("\n[Process exited with code \(exitCode)]")
    }

    private func appendSystemMessage(_ message: String) {
        // Add a system message line
        for char in message {
            buffer.write(char)
        }
        buffer.newLine()
        objectWillChange.send()
    }

    // MARK: - Input Handling

    /// Handle a key press event
    func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        guard isRunning else { return .ignored }

        var data: Data?

        // Handle modifier combinations
        if keyPress.modifiers.contains(.command) {
            // Let system handle Cmd combinations
            return .ignored
        }

        if keyPress.modifiers.contains(.control) {
            // Control key combinations
            if let char = keyPress.characters.first?.lowercased().first {
                let ctrlCode = char.asciiValue.map { Int($0) - 96 }
                if let code = ctrlCode, code > 0 && code < 32 {
                    data = Data([UInt8(code)])
                }
            }
        } else {
            // Regular keys
            switch keyPress.key {
            case .return:
                data = "\r".data(using: .utf8)

            case .delete:
                data = Data([0x7F]) // DEL

            case .tab:
                data = "\t".data(using: .utf8)

            case .escape:
                data = Data([0x1B])

            case .upArrow:
                data = "\u{1B}[A".data(using: .utf8)

            case .downArrow:
                data = "\u{1B}[B".data(using: .utf8)

            case .rightArrow:
                data = "\u{1B}[C".data(using: .utf8)

            case .leftArrow:
                data = "\u{1B}[D".data(using: .utf8)

            case .home:
                data = "\u{1B}[H".data(using: .utf8)

            case .end:
                data = "\u{1B}[F".data(using: .utf8)

            case .pageUp:
                data = "\u{1B}[5~".data(using: .utf8)

            case .pageDown:
                data = "\u{1B}[6~".data(using: .utf8)

            default:
                // Regular characters
                if let chars = keyPress.characters.data(using: .utf8) {
                    data = chars
                }
            }
        }

        if let data = data {
            Task {
                try? await ptyManager.write(data)
            }
            // Reset cursor visibility on input
            cursorVisible = true
            return .handled
        }

        return .ignored
    }

    /// Write a string directly to the PTY
    func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        Task {
            try? await ptyManager.write(data)
        }
    }

    // MARK: - Terminal Control

    /// Clear the terminal screen
    func clear() {
        buffer.clear()
        objectWillChange.send()
    }

    /// Resize the terminal
    func resize(rows: Int, columns: Int) {
        buffer.resize(rows: rows, columns: columns)

        Task {
            await ptyManager.resize(rows: UInt16(rows), cols: UInt16(columns))
        }

        objectWillChange.send()
    }

    /// Calculate terminal dimensions based on view size
    func calculateDimensions(width: CGFloat, height: CGFloat) -> (rows: Int, columns: Int) {
        let charWidth = font.characterWidth
        let lineHeight = font.lineHeight

        // Account for padding
        let availableWidth = width - 24 // 12pt padding on each side
        let availableHeight = height - 68 // Traffic light safe area (28pt) + status bar + padding

        let columns = max(10, Int(availableWidth / charWidth))
        let rows = max(5, Int(availableHeight / lineHeight))

        return (rows, columns)
    }

    // MARK: - Cleanup

    deinit {
        cursorBlinkTimer?.invalidate()
        updateDebouncer?.cancel()
    }
}

