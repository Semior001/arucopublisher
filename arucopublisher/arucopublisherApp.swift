//
//  arucopublisherApp.swift
//  arucopublisher
//
//  Created by Yelshat Duskaliyev on 27.03.2023.
//

import SwiftUI

@main
struct arucopublisherApp: App {
    @ObservedObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
            if state.settings {
                SettingsView().environmentObject(state)
            } else {
                ContentView().environmentObject(state)
            }
        }
    }

    // call test from OpenCVWrapper, to be sure that objc files are linked
    init() {
        NSLog("OpenCV-related files are linked and loaded: \(OpenCVWrapper.linkedAndLoaded())")
    }
}
