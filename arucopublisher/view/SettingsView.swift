//
// Created by Yelshat Duskaliyev on 17.04.2023.
//

import SwiftUI
import Foundation

struct SettingsView: View {
    @EnvironmentObject var state: AppState
    @State private var showAlert = false

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
                        // validate
                        let parts = targetServerAddress.split(separator: ":")
                        if parts.count != 2 {
                            showAlert.toggle()
                            return
                        }

                        state.settings = false
                    }).alert(isPresented: $showAlert) {
                        Alert(
                                title: Text("Invalid settings"),
                                message: Text("Correct settings before quit"),
                                dismissButton: .default(Text("OK"))
                        )
                    }
        }
    }

}
