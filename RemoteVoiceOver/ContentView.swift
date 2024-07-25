//
//  ContentView.swift
//  TestVoiceOver
//
//  Created by Vincent Neo on 24/7/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var listener = VoiceOverListener()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "circle.fill")
                    .font(.body)
                    .foregroundStyle(listener.isVoiceOverEnabled ? .green : .red)
                    .accessibilityHidden(true)
                Text("VoiceOver \(listener.isVoiceOverEnabled ? "On" : "Off")")
            }
            .font(.title2)
            .fontWeight(.bold)
            
            Section(header: sectionHeader) {
                Text("- App operates on port 80. Ensure port 80 is not used by other processes.")
                Text("- The \"Welcome to VoiceOver\" dialog seems to interfere with this app. Select \"Do not show this message again\" prior to using this app.")
                Text("- Accessibility permission is required for this app (Settings app > Privacy & Security > Accessibility)")
                Text("- Permission to control \"VoiceOver\" is required for app to work properly.")
                Text("- This app acts like a server. Quitting the app quits the server.")
            }
        }
        .padding()
    }
    
    private var sectionHeader: some View {
        Text("Notes")
            .font(.title3)
            .fontWeight(.semibold)
            .padding(.top, 16)
    }
}

//#Preview {
//    ContentView()
//}
