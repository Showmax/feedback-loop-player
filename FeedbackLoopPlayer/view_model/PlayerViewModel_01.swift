//
//  PlayerViewModel_01.swift
//  SimplePlayer
//
//  Created by Tomas Kohout on 28.03.2023.
//

import Foundation
import AVFoundation
import RxCocoa
import RxSwift

class PlayerViewModel_01: PlayerViewModel {
    // MARK: Private properties

    private let bag = DisposeBag()
    private let didInteractWithUIRelay = PublishRelay<Void>()
    private let didTapHUDRelay = PublishRelay<Void>()

    /// Whether HUD is currently displayed over the video
    private var isHUDVisible: Observable<Bool> {
        Observable.merge(
            // User tapped HUD
            didTapHUDRelay.map { true },

            // User has interacted with the UI in any way
            didInteractWithUIRelay.flatMapLatest {
                Observable.just(false).delay(.seconds(3), scheduler: MainScheduler.instance)
            }
        )
    }

    private lazy var stateDriver: Driver<PlayerState> = {
        Observable.combineLatest(
            player.rx.isPlaying,
            isHUDVisible
        ) {
            PlayerState(isPlaying: $0, isHUDVisible: $1, skipIntro: .hidden)
        }
        .asDriver(onErrorDriveWith: .empty())
    }()

    // MARK: Initialization
    init() {
        stateDriver.drive(
            onNext: { [weak self] in
                self?.state = $0
            }
        )
        .disposed(by: bag)
    }

    // MARK: Outputs
    let player = AVPlayer(url: PlayerConstants.streamURL)

    @Published var state: PlayerState = .initial

    // MARK: Inputs

    func didTapHUD() {
        didTapHUDRelay.accept(())
        didInteractWithUIRelay.accept(())
    }

    func didTogglePlay() {
        if state.isPlaying {
            player.pause()
        } else {
            player.play()
        }
        didInteractWithUIRelay.accept(())
    }

    func didSeekForward() {
        player.seek(to: player.currentTime() + PlayerConstants.incrementalSeek)
        didInteractWithUIRelay.accept(())
    }

    func didSeekBackward() {
        player.seek(to: player.currentTime() - PlayerConstants.incrementalSeek)
        didInteractWithUIRelay.accept(())
    }
}
