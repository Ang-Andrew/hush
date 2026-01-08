import AppKit
import CoreGraphics

actor InjectorService {
    
    func inject(text: String) async {
        let pasteboard = NSPasteboard.general
        let previousChangeCount = pasteboard.changeCount
        
        // 1. Capture current items (Best effort backup)
        // We only backup if it's string, otherwise we might skip restore or implement full item restore later
        let previousString = pasteboard.string(forType: .string)
        
        // 2. Write text
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // 3. Trigger Cmd+V
        simulatePasteCommand()
        
        // 4. Restore (Optional)
        // Wait a bit for the paste to register in the target app
        try? await Task.sleep(nanoseconds: 400_000_000) // 400ms
        
        if let original = previousString {
            // Check if user hasn't copied something new in the meantime
            if pasteboard.string(forType: .string) == text {
                 pasteboard.clearContents()
                 pasteboard.setString(original, forType: .string)
            }
        }
    }
    
    private func simulatePasteCommand() {
        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyCode: CGKeyCode = 9 // ANSI 'V'
        
        // Cmd Flag
        let cmdFlag = CGEventFlags.maskCommand
        
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) else { return }
        keyDown.flags = cmdFlag
        
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else { return }
        keyUp.flags = cmdFlag
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
