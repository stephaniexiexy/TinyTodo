import SwiftUI
import AppKit

@main
struct TinyTodoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 360, minHeight: 500)
                .background(Color(red: 0.985, green: 0.98, blue: 0.965))
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 390, height: 570)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            for window in NSApp.windows where window.contentView != nil {
                window.title = "Daily To-do"
                window.level = .floating
                window.isMovableByWindowBackground = true
                window.titlebarAppearsTransparent = true
                window.backgroundColor = NSColor(calibratedRed: 0.985, green: 0.98, blue: 0.965, alpha: 1)
                window.isReleasedWhenClosed = false
                window.setFrameAutosaveName("TinyTodoWindow")
            }
        }
    }
}
