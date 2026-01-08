This is a comprehensive prompt designed for an AI coding agent (like Antigravity or Cursor). It provides the specific architectural constraints needed to run performantly on a base M1 MacBook Air.

---

# Project Prompt: Local "Wispr Flow" Clone for macOS (M1 Optimized)

**Role:** Expert macOS Systems Engineer & Swift Developer
**Target Hardware:** MacBook Air M1 (8GB RAM baseline).
**Goal:** Build a native macOS menu bar application that mimics "Wispr Flow." It must provide near-instant voice-to-text dictation into *any* active text field using local inference only.

## 1. Core Constraints & Philosophy

* **Zero Network Usage:** All processing (VAD, Transcription) must happen on-device.
* **M1 Baseline Optimization:** The app must be lightweight. Inference must leverage the Apple Neural Engine (ANE) via CoreML to ensure <1s latency on a base M1 chip.
* **Native Only:** Use Swift, SwiftUI, and C++ (via bridging header for Whisper). No Electron, Python, or heavy frameworks.

## 2. Technical Stack

* **Language:** Swift 6.
* **UI:** SwiftUI (Settings & History Window).
* **Audio:** AVFoundation (AVAudioEngine) for raw PCM capture.
* **Input Monitoring:** CoreGraphics (`CGEventTap`) for global key listening.
* **Inference:** `whisper.cpp` (specifically the CoreML-accelerated build).
* **Data Persistence:** SwiftData or CoreData for transcript history.

## 3. Feature Specifications

### A. The Trigger (Global "Hold-to-Speak")

* **Interaction:** The user holds the `Fn` (Function) key to talk. Recording stops immediately upon release.
* **Implementation:**
* Create a `CGEventTap` to listen for global `.flagsChanged` events.
* Detect the specific keycode for the `Fn` modifier (typically `kVK_Function` or checking `CGEventFlags.maskSecondaryFn`).
* **Debounce:** Implement logic to prevent accidental triggers if the key is tapped quickly rather than held.



### B. Audio Engine (Low Latency)

* **Buffer Strategy:** Do NOT write audio to disk (SSD I/O is too slow for our latency target).
* **Mechanism:** Record directly into a circular buffer or append to a `Data` object in RAM.
* **Format:** 16kHz, 16-bit Mono PCM (native format for Whisper). Do not record at 44.1kHz and resample later; set the `AVAudioFormat` correctly at the source to save processing time.
* **Duration:** Support a strict maximum of 5 minutes of audio. (Approx ~10MB uncompressed, safe for RAM).

### C. The Intelligence (Whisper.cpp)

* **Model:** Use `base.en` converted to CoreML format.
* *Reasoning:* `tiny` is too inaccurate; `small` might miss the <1s latency target on M1 Air under load. `base.en` is the sweet spot.


* **Optimization:** The model must be pre-loaded into memory on app launch, not on key press.
* **Execution:** Run inference on a background actor to prevent UI blocking.

### D. Text Injection (Strategy B: Clipboard Emulation)

* **Workflow:**
1. **Capture:** Save the user's *current* clipboard content to a local variable.
2. **Set:** Place the transcribed text into the system clipboard.
3. **Paste:** Programmatically simulate a `Cmd+V` (Command + V) keystroke using `CGEventSource` and `CGEvent`.
4. **Restore:** (Optional but recommended) After a short delay (e.g., 200ms), restore the original clipboard content.


* **Reliability:** This must work in any app (Chrome, Notes, VS Code, Terminal).

### E. Transcript History UI

* Create a detached SwiftUI Window (floating or standard) accessible via the Menu Bar.
* **List View:** Show recorded segments with:
* Timestamp (e.g., "Today, 10:42 AM").
* Preview text (truncated).
* Full text (expandable).
* "Copy to Clipboard" button.



## 4. Implementation Steps for Agent

1. **Project Setup:** Initialize a macOS App (AppKit lifecycle or SwiftUI App) with "Accessory App" (Menu bar only) mode enabled in `Info.plist`.
2. **Permissions:** Add `Privacy - Microphone Usage Description` and `Accessibility` entitlements (required for `CGEventTap`).
3. **Whisper Integration:**
* Add `whisper.cpp` as a submodule or Swift Package.
* Create a `WhisperService` actor that handles model loading and runs `whisper_full`.


4. **Input Manager:**
* Implement `KeyMonitor` class using `CGEvent.tapCreate`.
* Bind the `.flagsChanged` event to `AudioRecorder.start()` and `AudioRecorder.stop()`.


5. **Audio Pipeline:**
* Setup `AVAudioEngine`.
* Install a tap on the input node to capture buffers.
* Convert buffers to `[Float]` array required by Whisper.


6. **Injection Service:**
* Implement the `PasteboardManager` to swap clipboard data and fire synthetic keypresses.



## 5. Critical Performance Metrics

* **Cold Start:** App must load the model within 2 seconds of launching.
* **Inference Latency:** On M1 Air, processing a 10-second sentence must complete in under 0.8 seconds.
* **Memory Footprint:** Keep total app usage under 500MB (Model is ~150MB, Audio buffer ~20MB, Swift overhead).