//
//  Chord_TrialApp.swift
//  Chord Trial
//
//  Created by David on 6/4/25.
//

import SwiftUI

@main
struct Chord_TrialApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SustainSettings())
        }
    }
}
