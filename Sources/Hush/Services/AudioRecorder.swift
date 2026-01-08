import Foundation
import AVFoundation

actor AudioRecorder {
    private let engine = AVAudioEngine()
    private var audioBuffer: [Float] = []
    private var isRecording = false
    
    // Whisper native format: 16kHz, Mono, Float32
    private let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
    
    private var converter: AVAudioConverter?
    private var inputFormat: AVAudioFormat?
    
    func checkPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized: return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        default: return false
        }
    }
    
    func startRecording() throws {
        self.audioBuffer.removeAll()
        
        let inputNode = engine.inputNode
        let hardwareFormat = inputNode.inputFormat(forBus: 0)
        self.inputFormat = hardwareFormat
        
        // Setup Converter
        guard let converter = AVAudioConverter(from: hardwareFormat, to: targetFormat) else {
            throw NSError(domain: "AudioRecorder", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio converter"])
        }
        self.converter = converter
        
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) { [weak self] (buffer, time) in
             // Extract data to a standard array or copy it to avoid Sendable issues
             guard let channelData = buffer.floatChannelData else { return }
             let channelPointer = channelData[0]
             let frameCount = Int(buffer.frameLength)
             let floatArray = Array(UnsafeBufferPointer(start: channelPointer, count: frameCount))
             
             // Now we pass the safe array (value type) to the actor
            Task { [weak self] in
                await self?.processRawBuffer(floatArray)
            }
        }
        
        try engine.start()
        isRecording = true
        print("Audio Recording started")
    }
    
    func stopRecording() -> [Float] {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
        print("Audio Recording stopped. Captured \(audioBuffer.count) samples.")
        return audioBuffer
    }
    
    private func processRawBuffer(_ inputFloats: [Float]) {
        guard let converter = self.converter, let format = self.inputFormat else { return }
        
        // Re-wrap input into a buffer for the converter (inefficient but safe for now)
        // Ideally we setup a ring buffer, but for quick fix:
        let frameCount = AVAudioFrameCount(inputFloats.count)
        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        inputBuffer.frameLength = frameCount
        
        if let data = inputBuffer.floatChannelData {
             // Copy back
             data[0].update(from: inputFloats, count: Int(frameCount))
        }
        
        // Output setup ...
        let ratio = targetFormat.sampleRate / format.sampleRate
        let outputCapacity = UInt32(Double(frameCount) * ratio)
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputCapacity) else { return }
        
        var error: NSError?
        let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }
        
        let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputCallback)
        
        if status != .error, let channelData = outputBuffer.floatChannelData {
            let channelPointer = channelData[0]
            let outCount = Int(outputBuffer.frameLength)
            if audioBuffer.count + outCount < 4_800_000 {
                 let floats = UnsafeBufferPointer(start: channelPointer, count: outCount)
                 audioBuffer.append(contentsOf: floats)
            }
        }
    }
}
