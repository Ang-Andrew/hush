# Hush 🤫

**Hush** is a lightning-fast, privacy-first voice dictation tool for macOS. Inspired by Wispr Flow, it allows you to speak into any text field simply by holding the `Fn` key.

Everything happens locally on your device using the Apple Neural Engine. No audio is ever sent to the cloud.

![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%2026+-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## Features

- **⚡️ Sub-Second Transcription:** Optimized with Whisper tiny.en model for <1s latency on most recordings
- **💎 Liquid Glass UI:** Beautiful macOS Tahoe-style translucent recording overlay using official `.glassEffect()` API
- **🔒 Private & Local:** All inference runs on-device using `whisper.cpp` and CoreML. Your voice data never leaves your machine
- **🍎 Native & Lightweight:** Built in pure Swift & SwiftUI. Optimized for Apple Silicon with multi-threaded processing
- **📝 Universal:** Works in ANY application—Notes, VS Code, Browser, Slack, Terminal, etc.
- **📋 Smart Injection:** Automatically pastes transcribed text at your cursor position

## Requirements

- **macOS:** 26.0 (Tahoe) or higher
- **Hardware:** Apple Silicon (M1/M2/M3/M4) for CoreML acceleration
- **Permissions:**
  - Accessibility (to listen for the `Fn` key)
  - Microphone (to capture audio)

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/Ang-Andrew/hush.git
cd hush
```

### 2. Download Models
Download the Whisper tiny.en model (optimized for speed):

```bash
mkdir -p ~/.hush/models
cd ~/.hush/models

# Download tiny.en model (~74MB)
curl -L -o ggml-tiny.en.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin

# Download CoreML encoder for GPU acceleration (~14MB)
curl -L -o ggml-tiny.en-encoder.mlmodelc.zip https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en-encoder.mlmodelc.zip
unzip ggml-tiny.en-encoder.mlmodelc.zip
rm ggml-tiny.en-encoder.mlmodelc.zip
```

### 3. Build & Run
```bash
swift build
.build/arm64-apple-macosx/debug/Hush
```

*Note: On first run, macOS will prompt you to grant Accessibility and Microphone permissions. You must enable Accessibility in System Settings for the app to detect the `Fn` key.*

## Usage

1. **Launch Hush** - You'll see a waveform icon in your menu bar
2. **Place your cursor** in any text input field
3. **Press and HOLD the `Fn` key** - A beautiful liquid glass overlay appears at the bottom of your screen
4. **Speak** your message
5. **Release the `Fn` key** - Text is transcribed and automatically pasted
6. **View History** - Click the menu bar icon to access previous transcriptions

## Performance

Typical latency on Apple Silicon (M1):
- **3-4 second recording:** ~0.5-0.7s transcription time
- **6-8 second recording:** ~0.8-1.2s transcription time
- **15+ second recording:** ~2-3s transcription time

Total latency from release to paste is typically under 1 second for short recordings.

## How It Works

Hush uses [whisper.cpp](https://github.com/ggerganov/whisper.cpp), a high-performance C++ port of OpenAI's Whisper model.

1. **Input Monitoring:** `CGEventTap` detects `Fn` key press/release globally
2. **Audio Capture:** `AVAudioEngine` records 16kHz mono audio while key is held
3. **Inference:** Audio processed locally via CoreML (Apple Neural Engine) with multi-threaded optimization
4. **Injection:** Text automatically pasted at cursor via system clipboard

## Technical Details

- **Model:** Whisper tiny.en (39M parameters, English-only)
- **Audio Format:** 16kHz, mono, Float32 PCM
- **Threading:** 2 threads optimized for tiny model
- **UI:** SwiftUI with native `.glassEffect(.clear)` material
- **Concurrency:** Swift 6 with strict concurrency checking

## License

MIT License. Feel free to use, modify, and distribute.
