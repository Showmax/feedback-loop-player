//
//  PlayerViewModel.swift
//  SimplePlayer
//
//  Created by Tomas Kohout on 28.03.2023.
//

import Foundation
import AVFoundation

enum SkipIntroState {
    case hidden
    case showing(secondsLeft: Int)
    case skipping
}

struct PlayerState {
    let isPlaying: Bool
    let isHUDVisible: Bool
    let skipIntro: SkipIntroState

    static let initial = PlayerState(isPlaying: false, isHUDVisible: false, skipIntro: .hidden)
}

protocol PlayerViewModel: ObservableObject {

    // MARK: Inputs
    func didTapHUD()
    func didTogglePlay()
    func didSeekForward()
    func didSeekBackward()

    // MARK: Outputs
    var player: AVPlayer { get }
    var state: PlayerState { get }
}
