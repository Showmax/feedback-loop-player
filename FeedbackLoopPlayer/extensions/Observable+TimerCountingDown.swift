//
//  Observable+TimerCountingDown.swift
//  SimplePlayer
//
//  Created by Tomas Kohout on 28.03.2023.
//

import RxSwift

extension Observable where Element == Int {
    static func timer(countingDownFrom: Int) -> Observable<Element> {
        return Observable<Int>.timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.instance)
        .map { timeElapsed in
            countingDownFrom - timeElapsed
        }
        .take(while: { $0 >= 0 })
    }
}
