//
//  transcript_ai_meetingApp.swift
//  transcript-ai-meeting
//
//  Created by Ali Siddique on 1/13/25.
//

import SwiftUI
import SwiftData
import SuperwallKit
@main
struct transcript_ai_meetingApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    init(){
        Superwall.configure(apiKey: "pk_1c37b7aa60daf40394803b68e48e5c82d491f18246140c8c")
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    Superwall.shared.register(event: "campaign_trigger")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
