//
// Created by Yelshat Duskaliyev on 17.04.2023.
//

import SwiftUI
import Foundation

struct SettingsView: View {
    @EnvironmentObject var state: AppState

    @AppStorage("targetServerAddress")
    private var targetServerAddress = ""
    @AppStorage("iso")
    private var iso = ""
    @AppStorage("exposure")
    private var exposure = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Target server address")) {
                    TextField("Target server address", text: $targetServerAddress)
                }
                Section(header: Text("Camera settings")) {
                    TextField("ISO", text: $iso)
                    TextField("Exposure", text: $exposure)
                }
            }.navigationTitle("Settings")
                    .navigationBarItems(trailing: Button("Done") {
                        state.settings = false
                    })
        }
    }

}
