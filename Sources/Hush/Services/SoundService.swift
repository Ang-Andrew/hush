
import Foundation
import AudioToolbox
import AppKit

@MainActor
class SoundService {
    // System Sound IDs reference: https://github.com/TUNER88/iOS-System-Sounds/blob/master/File%20Names%20of%20System%20Sounds
    // 1057: Tink
    // 1075: Hero (too long)
    // 1103: Tink (again?)
    // 1104: Tock
    // 1016: Tweet sent
    // 1001: MailReceived
    // 1113: Begin record (iOS) - might not be available on macOS standard
    // On macOS we can use NSSound generic names or system sounds.
    
    func playStartRecording() {
        // "Ding" - High pitch
        // Using "Tink" usually works well for this
        if let sound = NSSound(named: "Tink") {
            sound.play()
        } else {
             AudioServicesPlaySystemSound(1057)
        }
    }
    
    func playStopRecording() {
        // "Dong" - Lower pitch
        // "Basso" or "Bottle" might work
        if let sound = NSSound(named: "Bottle") {
            sound.play()
        } else {
            AudioServicesPlaySystemSound(1104) // Tock
        }
    }
    
    func playTranscriptionDing() {
         // Small pop-up sound
         if let sound = NSSound(named: "Pop") {
             sound.play()
         }
    }
}
