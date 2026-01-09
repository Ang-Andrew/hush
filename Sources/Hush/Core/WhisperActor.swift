import Foundation
import whisper

final class WhisperContextWrapper: @unchecked Sendable {
    let context: OpaquePointer
    
    init(context: OpaquePointer) {
        self.context = context
    }
    
    deinit {
        whisper_free(context)
    }
}

actor WhisperActor {
    private var contextWrapper: WhisperContextWrapper?
    private var isModelLoaded = false
    
    init() {
        Task.detached {
            await self.loadModel()
        }
    }
    
    private func loadModel() {
        // Path to the model - Using tiny.en for faster transcription
        // User needs to place the model here or we'd bundle it.
        // For CLI/Dev, we'll look in a known build location or user home.
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let modelPath = homeURL.appendingPathComponent(".hush/models/ggml-tiny.en.bin").path
        
        // Whisper setup params
        var params = whisper_context_default_params()
        params.use_gpu = true // Metal/CoreML usually handled via this or specific build flags
        
        // Initialize context
        if let ctx = whisper_init_from_file_with_params(modelPath, params) {
            self.contextWrapper = WhisperContextWrapper(context: ctx)
            self.isModelLoaded = true
            print("Whisper Model loaded successfully from \(modelPath)")
        } else {
            print("Failed to load Whisper model at \(modelPath). Please ensure ggml-base.en.bin is present.")
        }
    }
    
    func transcribe(audioBuffer: [Float]) -> String? {
        guard let wrapper = contextWrapper, isModelLoaded else {
            print("Model not loaded.")
            return nil
        }
        let context = wrapper.context

        // Validate audio buffer
        guard !audioBuffer.isEmpty else {
            print("Audio buffer is empty")
            return nil
        }

        // Check for invalid values (NaN, Inf)
        let hasInvalidValues = audioBuffer.contains { $0.isNaN || $0.isInfinite }
        if hasInvalidValues {
            print("Audio buffer contains invalid values (NaN or Inf)")
            return nil
        }

        // Pad audio to minimum 1 second (16000 samples) if needed
        var processBuffer = audioBuffer
        let minSamples = 16000
        if processBuffer.count < minSamples {
            let paddingNeeded = minSamples - processBuffer.count
            processBuffer.append(contentsOf: [Float](repeating: 0.0, count: paddingNeeded))
            print("Padded audio from \(audioBuffer.count) to \(processBuffer.count) samples")
        }

        print("Processing \(processBuffer.count) samples (\(Float(processBuffer.count)/16000.0)s of audio)")

        // Check if buffer has actual audio (not all zeros)
        let nonZeroCount = processBuffer.filter { abs($0) > 0.0001 }.count
        let percentNonZero = Float(nonZeroCount) / Float(processBuffer.count) * 100.0
        print("Buffer has \(nonZeroCount) non-zero samples (\(String(format: "%.1f", percentNonZero))%)")

        if nonZeroCount == 0 {
            print("ERROR: Audio buffer is all zeros (silence)")
            return nil
        }

        // Calculate RMS to verify audio level
        let sumSquares = processBuffer.reduce(0.0) { $0 + $1 * $1 }
        let rms = sqrt(sumSquares / Float(processBuffer.count))
        print("Audio RMS level: \(String(format: "%.6f", rms))")

        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.print_realtime = false
        params.print_progress = false
        params.print_timestamps = false
        params.single_segment = true  // Tiny model works better with single segment
        params.n_threads = 2  // Use 2 threads - tiny model is smaller
        params.translate = false  // Don't translate
        params.tdrz_enable = false  // Disable token-level timestamps for speed

        // CoreML is often enabled by checking if the CoreML model exists alongside.
        // whisper.cpp automatically prioritizes CoreML if the mlmodelc is present in the same dir.

        let ret = whisper_full(context, params, processBuffer, Int32(processBuffer.count))
        
        if ret != 0 {
            print("Whisper failed to process audio: \(ret)")
            return nil
        }
        
        let n_segments = whisper_full_n_segments(context)
        var resultText = ""
        
        for i in 0..<n_segments {
            if let textPtr = whisper_full_get_segment_text(context, i) {
                let text = String(cString: textPtr)
                resultText += text
            }
        }
        
        return resultText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
