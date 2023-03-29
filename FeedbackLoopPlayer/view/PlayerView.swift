//
//  PlayerView.swift
//  SimplePlayer
//
//  Created by Tomas Kohout on 28.03.2023.
//

import SwiftUI
import AVKit

struct PlayerView<ViewModel: PlayerViewModel>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        ZStack {
            player
            hud
        }
    }

    @ViewBuilder
    var player: some View {
        VideoPlayer(player: viewModel.player)
        .disabled(true)
    }

    @ViewBuilder
    var hud: some View {
        ZStack {
            Color.black.opacity(0.0001)
            if viewModel.state.isHUDVisible {
                Color.black.opacity(0.7)
                HStack(spacing: 32) {
                    Button("⏪️") { viewModel.didSeekBackward() }
                    Button(viewModel.state.isPlaying ? "⏸️" : "▶️") {
                        viewModel.didTogglePlay()
                    }
                    Button("⏩️") { viewModel.didSeekForward() }
                }
                .font(.system(size: 40))
            }

            SkipIntroView(viewModel: viewModel)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: viewModel.state.isHUDVisible)
        .onTapGesture {
            viewModel.didTapHUD()
        }
    }
}

struct SkipIntroView<ViewModel: PlayerViewModel>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack {
            Spacer()
            switch viewModel.state.skipIntro {
            case .showing(let secondsLeft):
                HStack {
                    Button("Watch intro") {}
                        .buttonStyle(.bordered)
                    Button("Skipping intro in \(secondsLeft)s ...") {}
                        .buttonStyle(.borderedProminent)
                }
                .padding(.bottom, 20)
            case .skipping:
                Button("Skipping ...") {}
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 20)
            case .hidden:
                EmptyView()
            }
        }
    }
}
