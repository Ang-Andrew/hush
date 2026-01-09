import Foundation
import Speech
import AVFoundation

actor SpeechRecognizer {
    private var recognizer: SFSpeechRecognizer?

    static func appendLog(_ msg: String) {
        if let data = msg.data(using: .utf8) {
            let fileURL = URL(fileURLWithPath: "/tmp/hush-speech.log")
            if FileManager.default.fileExists(atPath: "/tmp/hush-speech.log") {
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    try? fileHandle.close()
                }
            } else {
                try? data.write(to: fileURL)
            }
        }
    }

    init() {
        // Use en-US locale for now (best on-device support)
        // TODO: Try en-NZ or en-AU for better NZ accent support
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

        if recognizer == nil {
            print("❌ Speech recognition not available")
        } else {
            let locale = recognizer?.locale.identifier ?? "unknown"
            let onDevice = recognizer?.supportsOnDeviceRecognition ?? false
            print("✅ Speech recognizer initialized - locale: \(locale), on-device: \(onDevice)")
        }
    }

    func checkPermission() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        default:
            return false
        }
    }

    func transcribe(audioBuffer: [Float]) async -> String? {
        let logMsg = "🎤 SpeechRecognizer.transcribe() called with \(audioBuffer.count) samples\n"
        if let data = logMsg.data(using: .utf8) {
            let fileURL = URL(fileURLWithPath: "/tmp/hush-speech.log")
            if FileManager.default.fileExists(atPath: "/tmp/hush-speech.log") {
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    try? fileHandle.close()
                }
            } else {
                try? data.write(to: fileURL)
            }
        }
        print(logMsg)

        guard let recognizer = recognizer, recognizer.isAvailable else {
            let msg = "❌ Speech recognizer not available\n"
            Self.appendLog(msg)
            print(msg)
            return nil
        }
        let msg1 = "✅ Speech recognizer is available\n"
        Self.appendLog(msg1)
        print(msg1)

        // Check permission
        let msg2 = "🔑 Checking speech recognition permission...\n"
        Self.appendLog(msg2)
        let hasPermission = await checkPermission()
        guard hasPermission else {
            let msg3 = "❌ Speech recognition permission denied\n"
            Self.appendLog(msg3)
            print(msg3)
            return nil
        }
        let msg4 = "✅ Speech recognition permission granted\n"
        Self.appendLog(msg4)
        print(msg4)

        // Convert Float array to AVAudioPCMBuffer
        // Audio is 16kHz mono Float32
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!

        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(audioBuffer.count)) else {
            print("Failed to create PCM buffer")
            return nil
        }

        pcmBuffer.frameLength = AVAudioFrameCount(audioBuffer.count)

        if let channelData = pcmBuffer.floatChannelData {
            let channel = channelData[0]
            audioBuffer.withUnsafeBufferPointer { ptr in
                channel.update(from: ptr.baseAddress!, count: audioBuffer.count)
            }
        }

        // Create recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = false

        // Try on-device first, but don't require it if not available
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
            print("📦 Using on-device recognition")
        } else {
            request.requiresOnDeviceRecognition = false
            print("📦 On-device not supported, using server-based recognition")
        }

        print("📦 Created speech recognition request")

        // Append audio buffer
        request.append(pcmBuffer)
        request.endAudio()

        print("🎯 Starting recognition task...")

        return await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            var hasResumed = false

            recognizer.recognitionTask(with: request) { result, error in
                guard !hasResumed else {
                    let msg = "⚠️ Callback called but already resumed\n"
                    Self.appendLog(msg)
                    print(msg)
                    return
                }

                let msg1 = "📞 Recognition callback fired - result: \(result != nil), error: \(error != nil), isFinal: \(result?.isFinal ?? false)\n"
                Self.appendLog(msg1)
                print(msg1)

                if let error = error {
                    let msg2 = "❌ Speech recognition error: \(error.localizedDescription)\n"
                    Self.appendLog(msg2)
                    print(msg2)
                    hasResumed = true
                    continuation.resume(returning: nil)
                    return
                }

                if let result = result {
                    let msg3 = "📝 Got result, isFinal: \(result.isFinal), text: '\(result.bestTranscription.formattedString)'\n"
                    Self.appendLog(msg3)
                    print(msg3)
                    if result.isFinal {
                        let text = result.bestTranscription.formattedString
                        let msg4 = "✅ Speech recognition result: '\(text)'\n"
                        Self.appendLog(msg4)
                        print(msg4)
                        hasResumed = true
                        continuation.resume(returning: text)
                    }
                } else {
                    // No result and no error - finished with empty result
                    let msg5 = "⚠️ Speech recognition finished with no result\n"
                    Self.appendLog(msg5)
                    print(msg5)
                    hasResumed = true
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
