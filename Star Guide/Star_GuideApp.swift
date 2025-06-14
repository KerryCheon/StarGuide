//
//  Star_GuideApp.swift
//  Star Guide
//
//  Created by Kerry Cheon on 6/13/25.
//
import SwiftUI
import FirebaseCore

@main
struct Star_GuideApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
