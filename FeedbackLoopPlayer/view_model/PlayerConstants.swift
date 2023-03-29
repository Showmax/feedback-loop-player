//
//  PlayerConstants.swift
//  SimplePlayer
//
//  Created by Tomas Kohout on 28.03.2023.
//

import Foundation
import CoreMedia

struct PlayerConstants {
    static let streamURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")!

    static let incrementalSeek = CMTime(15)
    static let introStart = CMTime(15)
    static let introEnd = CMTime(60)
    static let skipIntroTime: Int = 10
}
