import Foundation
import CoreGraphics
import AppKit

@MainActor
class GlobalInputMonitor {
    var onFnPressed: (() -> Void)?
    var onFnReleased: (() -> Void)?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    private var isFnPressed = false
    private var debounceTask: Task<Void, Never>?
    
    // State machine
    private enum State {
        case idle
        case waitingForDebounce
        case recording
    }
    private var state: State = .idle
    
    func start() {
        // Request Accessibility Permissions if needed
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !accessEnabled {
            print("⚠️ ACCESSIBILITY NOT ENABLED! Please enable Accessibility for Hush in System Settings.")
            print("   Go to: System Settings → Privacy & Security → Accessibility")
        } else {
            print("✅ Accessibility permissions granted")
        }
        
        let eventMask = (1 << CGEventType.flagsChanged.rawValue)
        
        // Use a static callback that hops back to the instance
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: GlobalInputMonitor.eventCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap. Check permissions.")
            return
        }
        
        self.eventTap = tap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("GlobalInputMonitor started.")
    }
    
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
        }
    }
    
    private static let eventCallback: CGEventTapCallBack = { (proxy, type, event, refcon) in
        guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
        let monitor = Unmanaged<GlobalInputMonitor>.fromOpaque(refcon).takeUnretainedValue()
        
        if type == .flagsChanged {
            let flags = event.flags
            DispatchQueue.main.async {
                monitor.handleFlagsChanged(flags: flags)
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func handleFlagsChanged(flags: CGEventFlags) {
        // Check for Fn key (SecondaryFn)
        // Note: Fn key behavior can be tricky. It sets the secondaryFn mask.
        // We need to differentiate press vs release.
        // If the flag is present now and wasn't before? Or just check if it IS present.

        let isFnNow = flags.contains(.maskSecondaryFn)

        if isFnNow && !isFnPressed {
            // Key Down
            print("🔵 Fn key pressed")
            isFnPressed = true
            handleFnDown()
        } else if !isFnNow && isFnPressed {
            // Key Up
            print("🔴 Fn key released")
            isFnPressed = false
            handleFnUp()
        }
    }
    
    private func handleFnDown() {
        guard state == .idle else {
            print("⚠️ Fn down ignored - state is \(state)")
            return
        }
        state = .waitingForDebounce
        print("⏳ Starting debounce timer...")

        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            if Task.isCancelled { return }

            if self.isFnPressed {
                print("🎤 Starting recording!")
                self.state = .recording
                self.onFnPressed?()
            } else {
                print("⏭️ Fn released too quickly")
                self.state = .idle
            }
        }
    }

    private func handleFnUp() {
        debounceTask?.cancel()

        if state == .recording {
            print("🛑 Stopping recording!")
            state = .idle
            self.onFnReleased?()
        } else if state == .waitingForDebounce {
            print("⏭️ Released during debounce")
            state = .idle
        }
    }
}
