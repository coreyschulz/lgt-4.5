//
//  TerminalContentView.swift
//  liquid-glass-terminal
//
//  Main terminal display area using SwiftTerm with glass effect.
//

import SwiftUI

/// Terminal content display wrapping SwiftTerm
struct TerminalContentView: View {
    var state: TerminalState

    var body: some View {
        SwiftTermView(
            font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            state: state
        )
    }
}

#Preview {
    TerminalContentView(state: TerminalState())
        .frame(width: 800, height: 400)
}
