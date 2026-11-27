import SwiftUI

@main
struct Trip_AppApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            Group {
                if ProcessInfo.processInfo.arguments.contains("--component-gallery") {
                    ComponentGallery()
                } else {
                    ContentView()
                }
            }
            .modifier(DevelopmentAppearance())
            #else
            ContentView()
            #endif
        }
    }
}

#if DEBUG
private struct DevelopmentAppearance: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(ProcessInfo.processInfo.arguments.contains("--dark-mode") ? .dark : nil)
            .dynamicTypeSize(ProcessInfo.processInfo.arguments.contains("--large-text") ? .accessibility5 : dynamicTypeSize)
    }
}
#endif
