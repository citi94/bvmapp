//
//  bvmappApp.swift
//  bvmapp
//
//  Created by Peter Harding on 05/07/2025.
//

import SwiftUI
import SwiftData

@main
struct bvmappApp: App {
    @StateObject private var coordinator = AppCoordinator.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
        }
    }
}
