//
//  ContentView.swift
//  arucopublisher
//
//  Created by Yelshat Duskaliyev on 27.03.2023.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @StateObject private var model = FrameHandler()

    var body: some View {
        if let image = model.frame {
            Image(image, scale: 2.92, orientation: .up, label: Text("frame"))
                    .overlay(ImageOverlay(model: model)
                            .environmentObject(state),
                            alignment: .topLeading
                    )
        } else {
            Color.black
        }
    }
}

struct ImageOverlay: View {
    @EnvironmentObject var state: AppState
    @State var flash = false
    let model: FrameHandler

    @State var broadcast = false

    var body: some View {
        VStack {
            HStack {
                HStack {
                    Text("\(model.fps) fps")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    Text("processed within: \(Int((model.processedWithinSeconds * 1000).rounded())) μs")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                }.background(Color.black.opacity(0.5)).cornerRadius(5)

                Spacer()

                HStack {
                    Text("Flash")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    Toggle("", isOn: $flash).onChange(of: flash, perform: { value in
                        model.toggleFlash(value: value)
                    })
                    Button("Settings") {
                        model.stop()
                        state.settings = true
                    }
                }.background(Color.black.opacity(0.5)).cornerRadius(5)
            }.padding(10)

            Spacer()

            Button(broadcast ? "Stop broadcasting" : "Start broadcasting") {
                if !broadcast {
                    model.startBroadcast()
                } else {
                    model.stopBroadcast()
                }
                broadcast.toggle()
            }.padding(10)
                    .cornerRadius(5)
                    .background(broadcast ? Color.red : Color.green )
                    .foregroundColor(.white)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
