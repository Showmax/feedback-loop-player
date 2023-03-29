//
//  PlayerViewModel_03.swift
//  SimplePlayer
//
//  Created by Tomas Kohout on 28.03.2023.
//

import Foundation
import AVFoundation
import RxCocoa
import RxSwift

class PlayerViewModel_03: PlayerViewModel {
    // MARK: Nested Types
    enum HUDVisibilityAction {
        case hide
        case toggle
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
        Observable.merge(
            hasIntroStarted.flatMapLatest { hasCreditsStarted -> Observable<SkipIntroState> in
                if hasCreditsStarted {
                    return Observable<Int>.timer(countingDownFrom: PlayerConstants.skipIntroTime)
                        .map { secondsLeft in
                            secondsLeft > 0 ? .showing(secondsLeft: secondsLeft) : .skipping
                        }
                } else {
                    return .just(.hidden)
                }
            },

            // Hide when intro was skipped
            didSkipIntro.map { .hidden }
        )
        .share(replay: 1)
    }()


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

    // MARK: Initialization

    init() {
        stateDriver.drive(
            onNext: { [weak self] in
                self?.state = $0
            }
        )
        .disposed(by: bag)

        // Separate subscription to skipIntroState
        skipIntroState.subscribe(
            onNext: { [weak self] state in
                if case .skipping = state {
                    self?.player.seek(to: PlayerConstants.introEnd) { success in
                        if success {
                            self?.didSkipIntro.accept(())
                        }
                    }
                }
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

    private static func hudVisibilityReducer(state: Bool, action: HUDVisibilityAction) -> Bool {
        switch action {
        case .hide:
            return false
        case .toggle:
            return !state
        }
    }
}
