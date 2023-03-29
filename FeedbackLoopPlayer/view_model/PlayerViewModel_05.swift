//
//  PlayerViewModel.swift
//  SimplePlayer
//
//  Created by Tomas Kohout on 02.03.2023.
//

import Foundation
import AVFoundation
import RxCocoa
import RxSwift
import RxFeedback

class PlayerViewModel_05: PlayerViewModel {
    // MARK: Nested types
    enum HUDVisibilityAction {
        case hide
        case show
        case toggle
    }

    enum SkipIntroAction {
        case hasIntroStarted(Bool)
        case secondsLeftChanged(Int)
        case didSkipIntro
    }

    // MARK: Private properties
    private let bag = DisposeBag()

    private let didInteractWithUIRelay = PublishRelay<Void>()
    private let didTapHUDRelay = PublishRelay<Void>()
    private let didSkipIntro = PublishRelay<Void>()

    private var isHUDVisible: Observable<Bool> {
        Observable<HUDVisibilityAction>.merge(
            // Toggle HUD on tap
            didTapHUDRelay.map { .toggle },

            // Hide 3 seconds after interaction
            didInteractWithUIRelay.flatMapLatest {
                Observable.just(.hide).delay(.seconds(3), scheduler: MainScheduler.instance)
            }
        )
        .scan(false, accumulator: Self.hudVisibilityReducer)
        .startWith(false)
    }

    private lazy var skipIntroState: Observable<SkipIntroState> = {
        Observable.system(
            initialState: SkipIntroState.hidden,
            reduce: Self.skipIntroReducer,
            scheduler: MainScheduler.instance,
            feedback: [
                // 01 - Bind inputs
                { [hasIntroStarted] _ in
                    hasIntroStarted.map { SkipIntroAction.hasIntroStarted($0) }
                },

                // 02 - Update timer
                react(
                    request: {
                        guard case .showing(let secondsLeft) = $0 else { return nil }
                        return secondsLeft
                    },
                    effects: { secondsLeft in
                        Observable .just(.secondsLeftChanged(secondsLeft - 1)).delay(.seconds(1), scheduler: MainScheduler.instance)
                    }
                ),

                // 03 - Seek to skip intro
                react(
                    request: { state -> Bool? in
                        guard case .skipping = state else { return nil }
                        return true
                    },
                    effects: { [player] _ in
                        return player.rx.seek(to: PlayerConstants.introEnd).delay(.seconds(2), scheduler: MainScheduler.instance).andThen(.just(.didSkipIntro))
                    }
                )
            ]
        )
        .share(replay: 1)
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

    // MARK: Reducers
    private static func skipIntroReducer(state: SkipIntroState, action: SkipIntroAction) -> SkipIntroState {
        switch action {
        case .didSkipIntro:
            return .hidden
        case .hasIntroStarted(let hasIntroStarted):
            return hasIntroStarted ? .showing(secondsLeft: PlayerConstants.skipIntroTime) : .hidden
        case .secondsLeftChanged(let secondsLeft):
            return secondsLeft == 0 ? .skipping : .showing(secondsLeft: secondsLeft)
        }
    }

    private static func hudVisibilityReducer(state: Bool, action: HUDVisibilityAction) -> Bool {
        switch action {
        case .hide:
            return false
        case .show:
            return true
        case .toggle:
            return !state
        }
    }

    private var hasIntroStarted: Observable<Bool> {
        player.rx.time
            .map { $0 > PlayerConstants.introStart }
            .distinctUntilChanged()
    }

    private lazy var stateDriver: Driver<PlayerState> = {
        Observable.combineLatest(
            player.rx.isPlaying,
            isHUDVisible,
            skipIntroState
        ) {
            PlayerState(isPlaying: $0, isHUDVisible: $1, skipIntro: $2)
        }
        .asDriver(onErrorDriveWith: .empty())
    }()
}
