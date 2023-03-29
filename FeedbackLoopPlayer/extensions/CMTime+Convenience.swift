//
//  CMTime+Convenience.swift
//  SimplePlayer
//
//  Created by Tomas Kohout on 28.03.2023.
//
import CoreMedia

extension CMTime {
    init(_ seconds: Double) {
        self.init(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
}
