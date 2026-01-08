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
        // Path to the model - Hardcoded for M1 setup as per prompt requirements
        // User needs to place the model here or we'd bundle it.
        // For CLI/Dev, we'll look in a known build location or user home.
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let modelPath = homeURL.appendingPathComponent(".hush/models/ggml-base.en.bin").path
        
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
        
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.print_realtime = false
        params.print_progress = false
        params.print_timestamps = false
        params.single_segment = true
        
        // CoreML is often enabled by checking if the CoreML model exists alongside. 
        // whisper.cpp automatically prioritizes CoreML if the mlmodelc is present in the same dir.
        
        let ret = whisper_full(context, params, audioBuffer, Int32(audioBuffer.count))
        
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
