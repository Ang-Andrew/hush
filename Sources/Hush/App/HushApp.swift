import SwiftUI
import AppKit
import SwiftData

@main
struct HushApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra("Hush", systemImage: appState.isRecording ? "record.circle.fill" : "waveform.circle.fill") {
            HistoryMenuButton(appState: appState)
            
            Button("Clear History") {
                appState.clearHistory()
            }
            
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.menu)
    }
}

struct HistoryMenuButton: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        Button("History") {
            appState.showHistory()
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var isRecording = false
    
    let whisperActor: WhisperActor
    let inputMonitor: GlobalInputMonitor
    let audioRecorder: AudioRecorder
    let injector: InjectorService
    let historyManager: HistoryManager
    let soundService: SoundService
    
    let overlayModel = RecordingOverlayModel()
    private var historyWindow: NSWindow?
    private var overlayWindow: NSWindow?
    
    init() {
        self.historyManager = HistoryManager()
        self.whisperActor = WhisperActor()
        self.inputMonitor = GlobalInputMonitor()
        self.audioRecorder = AudioRecorder()
        self.injector = InjectorService()
        self.soundService = SoundService()
        
        self.inputMonitor.onFnPressed = { [weak self] in
            Task { await self?.startRecording() }
        }
        
        self.inputMonitor.onFnReleased = { [weak self] in
            Task { await self?.stopRecordingAndTranscribe() }
        }
        
        self.inputMonitor.start()
        
        // Setup volume callback
        Task {
            await self.audioRecorder.setVolumeHandler { [weak self] level in
                self?.overlayModel.updateLevel(level)
            }
        }
    }
    
    func showHistory() {
        if historyWindow == nil {
            let contentView = HistoryView()
                .environmentObject(self.historyManager)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.level = .floating
            window.title = "Dictation History"
            window.isReleasedWhenClosed = false
            window.center()
            window.contentView = NSHostingView(rootView: contentView)
            self.historyWindow = window
        }
        
        NSApp.activate(ignoringOtherApps: true)
        historyWindow?.makeKeyAndOrderFront(nil)
        historyWindow?.orderFrontRegardless()
    }
    
    private func showOverlay() {
        if overlayWindow == nil {
            let contentView = RecordingOverlayView(viewModel: overlayModel)

            // Create truly transparent window
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 150, height: 48),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.level = .floating
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false // View has its own shadow
            window.isReleasedWhenClosed = false
            window.ignoresMouseEvents = true  // Let clicks pass through
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]  // Always visible

            // Create hosting view with no background
            let hostingView = NSHostingView(rootView: contentView)
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = .clear

            window.contentView = hostingView

            // Position at bottom center - calculate after setting content
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                window.setFrame(NSRect(x: 0, y: 0, width: 150, height: 48), display: false)
                let x = screenRect.midX - (150 / 2)  // Use explicit width for accurate centering
                let y = screenRect.minY + 30  // Lower position - 30px from bottom
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }

            self.overlayWindow = window
        }

        overlayWindow?.orderFront(nil)
    }
    
    private func hideOverlay() {
        overlayWindow?.orderOut(nil)
    }
    
    func clearHistory() {
        historyManager.clear()
    }
    
    func startRecording() async {
        guard !isRecording else { return }
        isRecording = true
        
        let granted = await audioRecorder.checkPermission()
        guard granted else {
            print("Microphone permission denied")
            isRecording = false
            return
        }
        
        do {
            soundService.playStartRecording()
            showOverlay()
            try await audioRecorder.startRecording()
        } catch {
            print("Failed to start recording: \(error)")
            isRecording = false
            hideOverlay()
        }
    }
    
    func stopRecordingAndTranscribe() async {
        guard isRecording else { return }
        
        soundService.playStopRecording()
        hideOverlay() // Hide immediately for responsiveness
        
        let buffer = await audioRecorder.stopRecording()
        isRecording = false
        
        let startTime = Date()
        // print("Recording stopped. Starting transcription...")
        
        if let text = await whisperActor.transcribe(audioBuffer: buffer), !text.isEmpty {
            let transcriptionEnd = Date()
            let transcriptionDuration = transcriptionEnd.timeIntervalSince(startTime)
            print("Transcription Latency: \(String(format: "%.3f", transcriptionDuration))s")
            
            await injector.inject(text: text)
            
            let totalEnd = Date()
            let totalDuration = totalEnd.timeIntervalSince(startTime)
            print("Total Latency (End of Record -> Paste): \(String(format: "%.3f", totalDuration))s")
            
            historyManager.add(text: text)
        }
    }
}
