//
//  AVPlayer+Rx.swift
//  SimplePlayer
//
//  Created by Tomas Kohout on 02.03.2023.
//

import Foundation
import RxSwift
import RxCocoa
import AVFoundation

extension Reactive where Base == AVPlayer {
    public var timeControlStatus: Observable<AVPlayer.TimeControlStatus> {
        return base.rx
            .observe(AVPlayer.TimeControlStatus.self, #keyPath(AVPlayer.timeControlStatus))
            .map { $0 ?? .waitingToPlayAtSpecifiedRate }
            .startWith(base.timeControlStatus)
    }

    public var time: Observable<CMTime> {
        return Observable.create { [weak base = self.base] observer in
            guard let base else { return Disposables.create() }

            let observer = base.addPeriodicTimeObserver(forInterval: CMTime(1), queue: nil) { time in
                observer.onNext(time)
            }

            return Disposables.create { [weak base] in base?.removeTimeObserver(observer) }
        }
    }

    public var isPlaying: Observable<Bool> {
        timeControlStatus.map {
            switch $0 {
            case .paused, .waitingToPlayAtSpecifiedRate:
                return false
            case .playing:
                return true
            @unknown default:
                return false
            }
        }
    }

    public func seek(to time: CMTime) -> Completable {
        return Completable.create { [weak base = self.base] completable in
            base?.seek(to: time) { _ in
                completable(.completed)
            }
            return Disposables.create()
        }
    }
}
