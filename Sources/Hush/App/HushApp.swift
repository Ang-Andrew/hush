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
    
    private var historyWindow: NSWindow?
    
    init() {
        self.historyManager = HistoryManager()
        self.whisperActor = WhisperActor()
        self.inputMonitor = GlobalInputMonitor()
        self.audioRecorder = AudioRecorder()
        self.injector = InjectorService()
        
        self.inputMonitor.onFnPressed = { [weak self] in
            Task { await self?.startRecording() }
        }
        
        self.inputMonitor.onFnReleased = { [weak self] in
            Task { await self?.stopRecordingAndTranscribe() }
        }
        
        self.inputMonitor.start()
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
    
    func clearHistory() {
        historyManager.clear()
    }
    
    func startRecording() async {
        guard !isRecording else { return }
        
        let granted = await audioRecorder.checkPermission()
        guard granted else {
            print("Microphone permission denied")
            return
        }
        
        do {
            try await audioRecorder.startRecording()
            isRecording = true
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecordingAndTranscribe() async {
        guard isRecording else { return }
        
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
