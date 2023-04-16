//
//  arucopublisherApp.swift
//  arucopublisher
//
//  Created by Yelshat Duskaliyev on 27.03.2023.
//

import SwiftUI

@main
struct arucopublisherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    // call test from OpenCVWrapper, to be sure that objc files are linked
    init() {
        NSLog("OpenCV-related files are linked and loaded: \(OpenCVWrapper.linkedAndLoaded())")
    }
}
