//
//  WordpressBlogGeneratorApp.swift
//  WordpressBlogGenerator
//
//  Created by Junwoo Kwon on 1/15/26.
//

import SwiftUI
import Sparkle

@main
struct WordpressBlogGeneratorApp: App {
    @StateObject private var session = UserSession()

    // Start Sparkle (standard UI)
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        WindowGroup("Wordpress Blog Generator") {
            RootView()
                .environmentObject(session)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    updaterController.checkForUpdates(nil)
                }
            }
        }
    }
}


struct RootView: View {
    @EnvironmentObject var session: UserSession

    var body: some View {
        Group {
            if session.isLoading {
                ProgressView()
            } else if session.isAuthenticated {
                MainShellView()
            } else {
                AuthView()
            }
        }
        .task {
            await session.loadCurrentUser()
        }
    }
}
