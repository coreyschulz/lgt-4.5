//
//  PTYManager.swift
//  liquid-glass-terminal
//
//  Handles pseudo-terminal (PTY) creation and communication with the shell process.
//

import Foundation
import Darwin

/// Errors that can occur during PTY operations
enum PTYError: Error, LocalizedError {
    case openFailed
    case spawnFailed(Int32)
    case writeFailed
    case readFailed
    case notRunning

    var errorDescription: String? {
        switch self {
        case .openFailed: return "Failed to open PTY"
        case .spawnFailed(let code): return "Failed to spawn process (error: \(code))"
        case .writeFailed: return "Failed to write to PTY"
        case .readFailed: return "Failed to read from PTY"
        case .notRunning: return "Shell is not running"
        }
    }
}

/// Actor that manages PTY communication with the shell process
actor PTYManager {
    private var masterFD: Int32 = -1
    private var childPID: pid_t = 0
    private var isRunning = false

    /// Callback for when data is received from the shell
    private var dataCallback: (@Sendable (Data) -> Void)?

    /// Callback for when the shell process terminates
    private var terminateCallback: (@Sendable (Int32) -> Void)?

    /// Set the data received callback
    func setDataCallback(_ callback: @escaping @Sendable (Data) -> Void) {
        dataCallback = callback
    }

    /// Set the process terminated callback
    func setTerminateCallback(_ callback: @escaping @Sendable (Int32) -> Void) {
        terminateCallback = callback
    }

    /// Check if the shell is currently running
    var running: Bool {
        isRunning
    }

    /// Spawn a new shell process using posix_spawn
    /// - Parameters:
    ///   - shell: Path to the shell executable (default: /bin/zsh)
    ///   - environment: Additional environment variables
    ///   - size: Terminal dimensions (rows, cols)
    func spawn(
        shell: String = "/bin/zsh",
        environment: [String: String] = [:],
        size: (rows: UInt16, cols: UInt16) = (24, 80)
    ) async throws {
        // Create PTY pair using forkpty - this is the simplest approach
        // forkpty handles fork() internally in a way that's compatible
        var master: Int32 = 0
        var winSize = winsize(
            ws_row: size.rows,
            ws_col: size.cols,
            ws_xpixel: 0,
            ws_ypixel: 0
        )

        // Use forkpty which combines openpty + fork
        let pid = forkpty(&master, nil, nil, &winSize)

        if pid == -1 {
            throw PTYError.openFailed
        }

        if pid == 0 {
            // Child process - this runs in the forked process
            // Set up environment
            setenv("TERM", "xterm-256color", 1)
            setenv("COLORTERM", "truecolor", 1)
            setenv("LANG", "en_US.UTF-8", 1)

            for (key, value) in environment {
                setenv(key, value, 1)
            }

            // Execute shell
            let shellCString = shell.withCString { strdup($0) }
            let loginArg = "-l".withCString { strdup($0) }

            var args: [UnsafeMutablePointer<CChar>?] = [shellCString, loginArg, nil]
            execv(shell, &args)

            // If exec fails, exit child
            _exit(1)
        }

        // Parent process
        masterFD = master
        childPID = pid
        isRunning = true

        // Set non-blocking mode
        let flags = fcntl(masterFD, F_GETFL)
        _ = fcntl(masterFD, F_SETFL, flags | O_NONBLOCK)

        // Start reading from PTY
        startReadLoop()
    }

    /// Start the async read loop for PTY output
    private func startReadLoop() {
        let fd = masterFD
        let dataHandler = dataCallback
        let terminateHandler = terminateCallback
        let pid = childPID

        Task.detached { [weak self] in
            var buffer = [UInt8](repeating: 0, count: 8192)

            while true {
                // Check if still running
                let stillRunning = await self?.isRunning ?? false
                guard stillRunning else { break }

                let bytesRead = read(fd, &buffer, buffer.count)

                if bytesRead > 0 {
                    let data = Data(buffer[0..<bytesRead])
                    dataHandler?(data)
                } else if bytesRead == 0 {
                    // EOF - shell exited
                    break
                } else {
                    // Error or EAGAIN
                    if errno == EAGAIN || errno == EWOULDBLOCK {
                        // No data available, sleep briefly
                        try? await Task.sleep(for: .milliseconds(10))
                        continue
                    } else if errno == EINTR {
                        continue
                    } else {
                        // Real error
                        break
                    }
                }
            }

            // Clean up
            await self?.markTerminated()

            // Get exit status
            var status: Int32 = 0
            waitpid(pid, &status, 0)

            let exitCode: Int32
            if (status & 0x7f) == 0 {
                exitCode = (status >> 8) & 0xff
            } else {
                exitCode = -1
            }

            terminateHandler?(exitCode)
        }
    }

    /// Mark the PTY as terminated
    private func markTerminated() {
        isRunning = false
        if masterFD >= 0 {
            close(masterFD)
            masterFD = -1
        }
    }

    /// Write data to the PTY (send input to shell)
    /// - Parameter data: Data to write
    func write(_ data: Data) async throws {
        guard isRunning, masterFD >= 0 else {
            throw PTYError.notRunning
        }

        let fd = masterFD
        try data.withUnsafeBytes { buffer in
            guard let ptr = buffer.baseAddress else { return }
            let result = Darwin.write(fd, ptr, data.count)
            if result < 0 {
                throw PTYError.writeFailed
            }
        }
    }

    /// Write a string to the PTY
    /// - Parameter string: String to write
    func write(_ string: String) async throws {
        guard let data = string.data(using: .utf8) else { return }
        try await write(data)
    }

    /// Resize the terminal
    /// - Parameters:
    ///   - rows: Number of rows
    ///   - cols: Number of columns
    func resize(rows: UInt16, cols: UInt16) async {
        guard masterFD >= 0 else { return }

        var winSize = winsize(
            ws_row: rows,
            ws_col: cols,
            ws_xpixel: 0,
            ws_ypixel: 0
        )
        _ = ioctl(masterFD, TIOCSWINSZ, &winSize)

        // Send SIGWINCH to notify child of size change
        if childPID > 0 {
            kill(childPID, SIGWINCH)
        }
    }

    /// Terminate the shell process
    func terminate() async {
        guard isRunning else { return }

        isRunning = false

        if childPID > 0 {
            kill(childPID, SIGHUP)

            // Give the process a moment to exit gracefully
            try? await Task.sleep(for: .milliseconds(100))

            // Force kill if still running
            var status: Int32 = 0
            let result = waitpid(childPID, &status, WNOHANG)
            if result == 0 {
                kill(childPID, SIGKILL)
                waitpid(childPID, &status, 0)
            }
        }

        if masterFD >= 0 {
            close(masterFD)
            masterFD = -1
        }
    }

    deinit {
        if masterFD >= 0 {
            close(masterFD)
        }
    }
}
