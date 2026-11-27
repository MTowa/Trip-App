import SwiftUI

@main
struct Trip_AppApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--component-gallery") {
                ComponentGallery()
            } else {
                ContentView()
            }
            #else
            ContentView()
            #endif
        }
    }
}
