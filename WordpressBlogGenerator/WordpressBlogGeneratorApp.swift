//
//  WordpressBlogGeneratorApp.swift
//  WordpressBlogGenerator
//
//  Created by Junwoo Kwon on 1/15/26.
//

import SwiftUI

@main
struct WordpressBlogGeneratorApp: App {
    @StateObject private var session = UserSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
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
