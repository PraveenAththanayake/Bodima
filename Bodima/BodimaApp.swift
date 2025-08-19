//
//  BodimaApp.swift
//  Bodima
//
//  Created by Praveen Aththanayake on 2025-07-13.
//

import SwiftUI

@main
struct BodimaApp: App {
    // Register AppDelegate for handling push notifications
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
