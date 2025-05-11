//
//  borrowerApp.swift
//  borrower
//
//  Created by Eren Karaoğlu on 10.05.2025.
//

import SwiftUI


// Main application structure
@main
struct borrowerApp: App { // Changed app name here
    var body: some Scene {
        WindowGroup("Borrower") { // The title here might be overridden by hiddenTitleBar but is good practice
            ContentView()
                .containerBackground(.thinMaterial, for: .window) // Making the background glassy
        }
        .windowStyle(.hiddenTitleBar) // Hide the title bar for a more "panel" like look
    }
}
