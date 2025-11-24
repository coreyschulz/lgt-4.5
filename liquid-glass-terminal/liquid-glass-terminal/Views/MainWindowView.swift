//
//  MainWindowView.swift
//  liquid-glass-terminal
//
//  Root view with Liquid Glass styling.
//

import SwiftUI

/// Main window view with Liquid Glass effect
struct MainWindowView: View {
    @StateObject private var viewModel = TerminalViewModel()
    @State private var viewSize: CGSize = .zero

    /// Safe area height for traffic lights (close/minimize/zoom buttons)
    private let trafficLightSafeArea: CGFloat = 28

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Safe area spacer for traffic lights
                Color.clear
                    .frame(height: trafficLightSafeArea)

                // Terminal content area
                TerminalContentView(viewModel: viewModel)

                // Status bar (includes action buttons)
                StatusBarView(viewModel: viewModel)
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                handleResize(newSize)
            }
            .onAppear {
                viewSize = geometry.size
                handleResize(geometry.size)
                viewModel.startShell()
            }
        }
        .glassEffect(.regular, in: .rect)  // Rectangular edge-to-edge glass
        .ignoresSafeArea()
        .frame(minWidth: 400, minHeight: 300)
    }

    private func handleResize(_ size: CGSize) {
        let dims = viewModel.calculateDimensions(width: size.width, height: size.height)
        viewModel.resize(rows: dims.rows, columns: dims.columns)
    }
}

#Preview {
    MainWindowView()
        .frame(width: 800, height: 600)
}
