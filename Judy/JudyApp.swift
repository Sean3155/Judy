//
//  JudyApp.swift
//  Judy
//
//  Created by 유현우 on 3/9/26.
//

import SwiftUI

@main
struct JudyApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView(authManager: authManager)
                .environmentObject(authManager)
        }
    }
}
