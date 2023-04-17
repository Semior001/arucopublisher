//
//  ContentView.swift
//  arucopublisher
//
//  Created by Yelshat Duskaliyev on 27.03.2023.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var model = FrameHandler()
    
    var body: some View {
        FrameView(image: model.frame)
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
