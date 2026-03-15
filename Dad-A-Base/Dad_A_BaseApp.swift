//
//  Dad_A_BaseApp.swift
//  Dad-A-Base
//
//  Created by Andrew Pitblado on 2026-03-13.
//

import SwiftUI
import SwiftData

@main
struct Dad_A_BaseApp: App {

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [FavoriteJoke.self])
    }
}
