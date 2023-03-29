//
//  ContentView.swift
//  SimplePlayer
//
//  Created by Tomas Kohout on 02.03.2023.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("01 Simple stream") {
                    PlayerView(viewModel: PlayerViewModel_01())
                        .navigationTitle("01 Simple stream")
                }
                NavigationLink("02 Reducer") {
                    PlayerView(viewModel: PlayerViewModel_02())
                        .navigationTitle("02 Reducer")
                }
                NavigationLink("03 Skip intro with relay") {
                    PlayerView(viewModel: PlayerViewModel_03())
                        .navigationTitle("03 Skip intro with relay")
                }
                NavigationLink("04 Skip intro with RxFeedback") {
                    PlayerView(viewModel: PlayerViewModel_04())
                        .navigationTitle("03 Skip intro with RxFeedback")
                }
                NavigationLink("05 Skip intro with RxFeedback +") {
                    PlayerView(viewModel: PlayerViewModel_05())
                        .navigationTitle("05 Skip intro with RxFeedback +")
                }
            }
        }
    }
}
