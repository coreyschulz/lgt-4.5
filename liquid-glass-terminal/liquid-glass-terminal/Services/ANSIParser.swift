//
//  ANSIParser.swift
//  liquid-glass-terminal
//
//  State machine parser for ANSI escape sequences.
//

import Foundation
import AppKit

/// Protocol for receiving parsed ANSI events
protocol ANSIParserDelegate: AnyObject {
    func parser(_ parser: ANSIParser, didReceiveText text: String)
    func parser(_ parser: ANSIParser, didReceiveControlCharacter char: UInt8)
    func parser(_ parser: ANSIParser, didReceiveCSI command: Character, params: [Int], intermediates: [Character])
    func parser(_ parser: ANSIParser, didReceiveOSC command: Int, data: String)
    func parser(_ parser: ANSIParser, didReceiveEscape char: Character)
}

/// State machine parser for ANSI/VT100 escape sequences
class ANSIParser {
    weak var delegate: ANSIParserDelegate?

    /// Parser state machine states
    private enum State {
        case ground
        case escape
        case escapeIntermediate
        case csiEntry
        case csiParam
        case csiIntermediate
        case csiIgnore
        case oscString
        case oscEnd
    }

    private var state: State = .ground
    private var params: [Int] = []
    private var currentParam: Int = 0
    private var hasParam: Bool = false
    private var intermediates: [Character] = []
    private var oscData: String = ""
    private var oscCommand: Int = 0
    private var textBuffer: String = ""

    /// Parse a chunk of data
    func parse(_ data: Data) {
        for byte in data {
            process(byte)
        }
        flushTextBuffer()
    }

    /// Parse a string
    func parse(_ string: String) {
        if let data = string.data(using: .utf8) {
            parse(data)
        }
    }

    /// Process a single byte
    private func process(_ byte: UInt8) {
        switch state {
        case .ground:
            handleGround(byte)
        case .escape:
            handleEscape(byte)
        case .escapeIntermediate:
            handleEscapeIntermediate(byte)
        case .csiEntry:
            handleCSIEntry(byte)
        case .csiParam:
            handleCSIParam(byte)
        case .csiIntermediate:
            handleCSIIntermediate(byte)
        case .csiIgnore:
            handleCSIIgnore(byte)
        case .oscString:
            handleOSCString(byte)
        case .oscEnd:
            handleOSCEnd(byte)
        }
    }

    // MARK: - State Handlers

    private func handleGround(_ byte: UInt8) {
        switch byte {
        case 0x00...0x1A, 0x1C...0x1F:
            // C0 control characters (except ESC)
            flushTextBuffer()
            delegate?.parser(self, didReceiveControlCharacter: byte)

        case 0x1B: // ESC
            flushTextBuffer()
            state = .escape

        case 0x20...0x7E:
            // Printable ASCII
            textBuffer.append(Character(UnicodeScalar(byte)))

        case 0x7F:
            // DEL - ignore
            break

        case 0x80...0xFF:
            // UTF-8 continuation or start byte
            textBuffer.append(Character(UnicodeScalar(byte)))

        default:
            break
        }
    }

    private func handleEscape(_ byte: UInt8) {
        switch byte {
        case 0x20...0x2F:
            // Intermediate bytes
            intermediates.append(Character(UnicodeScalar(byte)))
            state = .escapeIntermediate

        case 0x30...0x4F, 0x51...0x57, 0x59, 0x5A, 0x5C, 0x60...0x7E:
            // Final byte - simple escape sequence
            delegate?.parser(self, didReceiveEscape: Character(UnicodeScalar(byte)))
            state = .ground

        case 0x50: // DCS
            // Device Control String - ignore for now
            state = .ground

        case 0x58, 0x5E, 0x5F: // SOS, PM, APC
            // String sequences - ignore for now
            state = .ground

        case 0x5B: // CSI
            params = []
            currentParam = 0
            hasParam = false
            intermediates = []
            state = .csiEntry

        case 0x5D: // OSC
            oscData = ""
            oscCommand = 0
            state = .oscString

        case 0x1B: // Another ESC
            // Stay in escape state
            break

        default:
            // Unknown - return to ground
            state = .ground
        }
    }

    private func handleEscapeIntermediate(_ byte: UInt8) {
        switch byte {
        case 0x20...0x2F:
            intermediates.append(Character(UnicodeScalar(byte)))

        case 0x30...0x7E:
            // Final byte
            delegate?.parser(self, didReceiveEscape: Character(UnicodeScalar(byte)))
            intermediates = []
            state = .ground

        default:
            intermediates = []
            state = .ground
        }
    }

    private func handleCSIEntry(_ byte: UInt8) {
        switch byte {
        case 0x30...0x39: // 0-9
            currentParam = Int(byte - 0x30)
            hasParam = true
            state = .csiParam

        case 0x3A: // :
            // Sub-parameter delimiter (ignore for now)
            state = .csiParam

        case 0x3B: // ;
            // Empty parameter
            params.append(0)
            state = .csiParam

        case 0x3C...0x3F: // < = > ?
            // Private parameter prefix
            intermediates.append(Character(UnicodeScalar(byte)))
            state = .csiParam

        case 0x20...0x2F:
            // Intermediate byte
            intermediates.append(Character(UnicodeScalar(byte)))
            state = .csiIntermediate

        case 0x40...0x7E:
            // Final byte (no params)
            executeCSI(command: Character(UnicodeScalar(byte)))
            state = .ground

        default:
            state = .ground
        }
    }

    private func handleCSIParam(_ byte: UInt8) {
        switch byte {
        case 0x30...0x39: // 0-9
            currentParam = currentParam * 10 + Int(byte - 0x30)
            hasParam = true

        case 0x3A: // :
            // Sub-parameter - ignore
            break

        case 0x3B: // ;
            params.append(hasParam ? currentParam : 0)
            currentParam = 0
            hasParam = false

        case 0x3C...0x3F: // < = > ?
            // Should only appear at start, ignore here
            break

        case 0x20...0x2F:
            // Intermediate byte
            if hasParam {
                params.append(currentParam)
            }
            intermediates.append(Character(UnicodeScalar(byte)))
            state = .csiIntermediate

        case 0x40...0x7E:
            // Final byte
            if hasParam {
                params.append(currentParam)
            }
            executeCSI(command: Character(UnicodeScalar(byte)))
            state = .ground

        default:
            state = .csiIgnore
        }
    }

    private func handleCSIIntermediate(_ byte: UInt8) {
        switch byte {
        case 0x20...0x2F:
            intermediates.append(Character(UnicodeScalar(byte)))

        case 0x40...0x7E:
            executeCSI(command: Character(UnicodeScalar(byte)))
            state = .ground

        default:
            state = .csiIgnore
        }
    }

    private func handleCSIIgnore(_ byte: UInt8) {
        if byte >= 0x40 && byte <= 0x7E {
            state = .ground
        }
    }

    private func handleOSCString(_ byte: UInt8) {
        switch byte {
        case 0x07: // BEL - OSC terminator
            executeOSC()
            state = .ground

        case 0x1B: // ESC - possible ST
            state = .oscEnd

        case 0x20...0x7E:
            oscData.append(Character(UnicodeScalar(byte)))

        default:
            break
        }
    }

    private func handleOSCEnd(_ byte: UInt8) {
        if byte == 0x5C { // Backslash (ST = ESC \)
            executeOSC()
            state = .ground
        } else {
            // Not ST, include ESC in data and continue
            oscData.append("\u{1B}")
            state = .oscString
            handleOSCString(byte)
        }
    }

    // MARK: - Command Execution

    private func executeCSI(command: Character) {
        delegate?.parser(self, didReceiveCSI: command, params: params, intermediates: intermediates)
        params = []
        currentParam = 0
        hasParam = false
        intermediates = []
    }

    private func executeOSC() {
        // Parse OSC command number from data
        let parts = oscData.split(separator: ";", maxSplits: 1)
        if let first = parts.first, let cmd = Int(first) {
            oscCommand = cmd
            let data = parts.count > 1 ? String(parts[1]) : ""
            delegate?.parser(self, didReceiveOSC: cmd, data: data)
        }
        oscData = ""
        oscCommand = 0
    }

    private func flushTextBuffer() {
        if !textBuffer.isEmpty {
            delegate?.parser(self, didReceiveText: textBuffer)
            textBuffer = ""
        }
    }

    /// Reset parser to initial state
    func reset() {
        state = .ground
        params = []
        currentParam = 0
        hasParam = false
        intermediates = []
        oscData = ""
        oscCommand = 0
        textBuffer = ""
    }
}

// MARK: - Terminal Emulator (Interprets parsed sequences)

/// Interprets parsed ANSI sequences and updates the terminal buffer
class TerminalEmulator: ANSIParserDelegate {
    private let buffer: TerminalBuffer
    private let parser = ANSIParser()

    /// Saved cursor position
    private var savedCursor: CursorState?

    init(buffer: TerminalBuffer) {
        self.buffer = buffer
        parser.delegate = self
    }

    /// Process incoming data from PTY
    func process(_ data: Data) {
        parser.parse(data)
    }

    // MARK: - ANSIParserDelegate

    func parser(_ parser: ANSIParser, didReceiveText text: String) {
        for char in text {
            buffer.write(char)
        }
    }

    func parser(_ parser: ANSIParser, didReceiveControlCharacter char: UInt8) {
        switch char {
        case 0x07: // BEL
            NSSound.beep()

        case 0x08: // BS (Backspace)
            if buffer.cursor.column > 0 {
                buffer.cursor.column -= 1
            }

        case 0x09: // HT (Tab)
            // Move to next tab stop (every 8 columns)
            let nextTab = ((buffer.cursor.column / 8) + 1) * 8
            buffer.cursor.column = min(nextTab, buffer.columns - 1)

        case 0x0A, 0x0B, 0x0C: // LF, VT, FF
            buffer.newLine()

        case 0x0D: // CR
            buffer.carriageReturn()

        default:
            break
        }
    }

    func parser(_ parser: ANSIParser, didReceiveCSI command: Character, params: [Int], intermediates: [Character]) {
        // Check for private mode prefix
        let isPrivate = intermediates.first == "?"

        switch command {
        case "A": // CUU - Cursor Up
            let n = max(1, params.first ?? 1)
            buffer.cursor.row = max(0, buffer.cursor.row - n)

        case "B": // CUD - Cursor Down
            let n = max(1, params.first ?? 1)
            buffer.cursor.row = min(buffer.rows - 1, buffer.cursor.row + n)

        case "C": // CUF - Cursor Forward
            let n = max(1, params.first ?? 1)
            buffer.cursor.column = min(buffer.columns - 1, buffer.cursor.column + n)

        case "D": // CUB - Cursor Back
            let n = max(1, params.first ?? 1)
            buffer.cursor.column = max(0, buffer.cursor.column - n)

        case "E": // CNL - Cursor Next Line
            let n = max(1, params.first ?? 1)
            buffer.cursor.row = min(buffer.rows - 1, buffer.cursor.row + n)
            buffer.cursor.column = 0

        case "F": // CPL - Cursor Previous Line
            let n = max(1, params.first ?? 1)
            buffer.cursor.row = max(0, buffer.cursor.row - n)
            buffer.cursor.column = 0

        case "G": // CHA - Cursor Horizontal Absolute
            let col = max(1, params.first ?? 1) - 1
            buffer.cursor.column = min(buffer.columns - 1, col)

        case "H", "f": // CUP - Cursor Position
            let row = max(1, params.first ?? 1) - 1
            let col = params.count > 1 ? max(1, params[1]) - 1 : 0
            buffer.moveCursor(row: row, column: col)

        case "J": // ED - Erase in Display
            let mode = params.first ?? 0
            switch mode {
            case 0: buffer.clearToEndOfScreen()
            case 1: break // Clear from start to cursor (not implemented)
            case 2, 3: buffer.clear()
            default: break
            }

        case "K": // EL - Erase in Line
            let mode = params.first ?? 0
            switch mode {
            case 0: buffer.clearToEndOfLine()
            case 1: break // Clear from start to cursor (not implemented)
            case 2: // Clear entire line
                for i in 0..<buffer.columns {
                    buffer.lines[buffer.cursor.row].cells[i] = TerminalCell()
                }
            default: break
            }

        case "L": // IL - Insert Lines
            let n = max(1, params.first ?? 1)
            for _ in 0..<n {
                if buffer.cursor.row < buffer.rows {
                    buffer.lines.insert(TerminalLine(columns: buffer.columns), at: buffer.cursor.row)
                    if buffer.lines.count > buffer.rows {
                        buffer.lines.removeLast()
                    }
                }
            }

        case "M": // DL - Delete Lines
            let n = max(1, params.first ?? 1)
            for _ in 0..<n {
                if buffer.cursor.row < buffer.lines.count {
                    buffer.lines.remove(at: buffer.cursor.row)
                    buffer.lines.append(TerminalLine(columns: buffer.columns))
                }
            }

        case "P": // DCH - Delete Characters
            let n = max(1, params.first ?? 1)
            let row = buffer.cursor.row
            let col = buffer.cursor.column
            for _ in 0..<n {
                if col < buffer.lines[row].cells.count {
                    buffer.lines[row].cells.remove(at: col)
                    buffer.lines[row].cells.append(TerminalCell())
                }
            }

        case "@": // ICH - Insert Characters
            let n = max(1, params.first ?? 1)
            let row = buffer.cursor.row
            let col = buffer.cursor.column
            for _ in 0..<n {
                buffer.lines[row].cells.insert(TerminalCell(), at: col)
                if buffer.lines[row].cells.count > buffer.columns {
                    buffer.lines[row].cells.removeLast()
                }
            }

        case "m": // SGR - Select Graphic Rendition
            handleSGR(params)

        case "h": // SM - Set Mode
            handleMode(params, set: true, isPrivate: isPrivate)

        case "l": // RM - Reset Mode
            handleMode(params, set: false, isPrivate: isPrivate)

        case "r": // DECSTBM - Set Scrolling Region
            // Simplified - not fully implementing scroll regions
            break

        case "s": // SCP - Save Cursor Position
            savedCursor = buffer.cursor

        case "u": // RCP - Restore Cursor Position
            if let saved = savedCursor {
                buffer.cursor = saved
            }

        case "c": // DA - Device Attributes
            // Should respond with terminal identification
            break

        case "n": // DSR - Device Status Report
            // Should respond with cursor position
            break

        default:
            break
        }
    }

    func parser(_ parser: ANSIParser, didReceiveOSC command: Int, data: String) {
        switch command {
        case 0, 2: // Set window title
            // Could implement window title change
            break
        default:
            break
        }
    }

    func parser(_ parser: ANSIParser, didReceiveEscape char: Character) {
        switch char {
        case "7": // DECSC - Save Cursor
            savedCursor = buffer.cursor

        case "8": // DECRC - Restore Cursor
            if let saved = savedCursor {
                buffer.cursor = saved
            }

        case "D": // IND - Index (move down, scroll if at bottom)
            if buffer.cursor.row < buffer.rows - 1 {
                buffer.cursor.row += 1
            } else {
                buffer.scrollUp()
            }

        case "E": // NEL - Next Line
            buffer.carriageReturn()
            if buffer.cursor.row < buffer.rows - 1 {
                buffer.cursor.row += 1
            } else {
                buffer.scrollUp()
            }

        case "M": // RI - Reverse Index (move up, scroll if at top)
            if buffer.cursor.row > 0 {
                buffer.cursor.row -= 1
            }
            // Scroll down not implemented

        case "c": // RIS - Reset
            buffer.clear()
            buffer.resetAttributes()

        default:
            break
        }
    }

    // MARK: - Helpers

    private func handleSGR(_ params: [Int]) {
        var params = params
        if params.isEmpty {
            params = [0]
        }

        var i = 0
        while i < params.count {
            let code = params[i]

            switch code {
            case 0:
                buffer.resetAttributes()

            case 1:
                buffer.currentAttributes.insert(.bold)

            case 2:
                buffer.currentAttributes.insert(.dim)

            case 3:
                buffer.currentAttributes.insert(.italic)

            case 4:
                buffer.currentAttributes.insert(.underline)

            case 5, 6:
                buffer.currentAttributes.insert(.blink)

            case 7:
                buffer.currentAttributes.insert(.inverse)

            case 8:
                buffer.currentAttributes.insert(.hidden)

            case 9:
                buffer.currentAttributes.insert(.strikethrough)

            case 22:
                buffer.currentAttributes.remove(.bold)
                buffer.currentAttributes.remove(.dim)

            case 23:
                buffer.currentAttributes.remove(.italic)

            case 24:
                buffer.currentAttributes.remove(.underline)

            case 25:
                buffer.currentAttributes.remove(.blink)

            case 27:
                buffer.currentAttributes.remove(.inverse)

            case 28:
                buffer.currentAttributes.remove(.hidden)

            case 29:
                buffer.currentAttributes.remove(.strikethrough)

            case 30...37:
                buffer.currentForeground = .ansi(UInt8(code - 30))

            case 38:
                // Extended foreground color
                if i + 2 < params.count && params[i + 1] == 5 {
                    // 256 color mode
                    buffer.currentForeground = .palette(UInt8(params[i + 2]))
                    i += 2
                } else if i + 4 < params.count && params[i + 1] == 2 {
                    // True color RGB
                    buffer.currentForeground = .rgb(
                        UInt8(params[i + 2]),
                        UInt8(params[i + 3]),
                        UInt8(params[i + 4])
                    )
                    i += 4
                }

            case 39:
                buffer.currentForeground = .default

            case 40...47:
                buffer.currentBackground = .ansi(UInt8(code - 40))

            case 48:
                // Extended background color
                if i + 2 < params.count && params[i + 1] == 5 {
                    buffer.currentBackground = .palette(UInt8(params[i + 2]))
                    i += 2
                } else if i + 4 < params.count && params[i + 1] == 2 {
                    buffer.currentBackground = .rgb(
                        UInt8(params[i + 2]),
                        UInt8(params[i + 3]),
                        UInt8(params[i + 4])
                    )
                    i += 4
                }

            case 49:
                buffer.currentBackground = .default

            case 90...97:
                // Bright foreground colors
                buffer.currentForeground = .ansi(UInt8(code - 90 + 8))

            case 100...107:
                // Bright background colors
                buffer.currentBackground = .ansi(UInt8(code - 100 + 8))

            default:
                break
            }

            i += 1
        }
    }

    private func handleMode(_ params: [Int], set: Bool, isPrivate: Bool) {
        for param in params {
            if isPrivate {
                switch param {
                case 1: // DECCKM - Application cursor keys
                    break
                case 25: // DECTCEM - Text cursor enable
                    buffer.cursor.visible = set
                case 47, 1047: // Alternate screen buffer
                    if set {
                        buffer.switchToAlternateScreen()
                    } else {
                        buffer.switchToMainScreen()
                    }
                case 1049: // Alternate screen with cursor save
                    if set {
                        savedCursor = buffer.cursor
                        buffer.switchToAlternateScreen()
                    } else {
                        buffer.switchToMainScreen()
                        if let saved = savedCursor {
                            buffer.cursor = saved
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}
