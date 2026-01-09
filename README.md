# Hush 🤫

**Hush** is a voice dictation tool for macOS. Inspired by Wispr Flow, it allows you to speak into any text field by holding the `Fn` key.

This branch uses Apple's native SFSpeechRecognizer for fast, accurate transcription with excellent accent support. Everything happens on-device using Apple's Neural Engine.

> **Note:** For a fully offline version using Whisper (no system dependencies), see the `main` branch.

![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%2026+-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## Features

- **⚡️ Fast Transcription:** Uses Apple's native SFSpeechRecognizer with near-instant transcription
- **🌍 Accent Support:** Excellent recognition for diverse English accents (US, UK, NZ, AU, etc.)
- **💎 Liquid Glass UI:** macOS Tahoe-style translucent recording overlay using `.glassEffect()` API
- **🔒 On-Device Processing:** All inference runs locally using Apple's Neural Engine
- **🍎 Native:** Built in Swift & SwiftUI, deeply integrated with macOS
- **📝 Universal:** Works in any application—Notes, VS Code, Browser, Slack, Terminal, etc.
- **📋 Auto-paste:** Transcribed text is automatically pasted at your cursor position

## Requirements

- **macOS:** 26.0 (Tahoe) or higher
- **Hardware:** Apple Silicon (M1/M2/M3/M4) recommended
- **System Settings:**
  - **Siri and Dictation** must be enabled (System Settings → Siri & Spotlight → Enable "Ask Siri")
- **Permissions:**
  - Accessibility (to listen for the `Fn` key)
  - Microphone (to capture audio)
  - Speech Recognition (granted on first use)

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/Ang-Andrew/hush.git
cd hush
git checkout apple-speech  # Switch to Apple Speech branch
```

### 2. Enable Siri and Dictation
Before building, ensure Siri is enabled:
1. Open **System Settings**
2. Go to **Siri & Spotlight**
3. Toggle **Ask Siri** to ON

### 3. Build & Run
```bash
swift build
.build/arm64-apple-macosx/debug/Hush
```

*Note: On first run, macOS will prompt you to grant Accessibility, Microphone, and Speech Recognition permissions. You must enable Accessibility in System Settings for the app to detect the `Fn` key.*

## Usage

1. **Launch Hush** - You'll see a waveform icon in your menu bar
2. **Place your cursor** in any text input field
3. **Press and HOLD the `Fn` key** - A liquid glass overlay appears at the bottom of your screen
4. **Speak** your message
5. **Release the `Fn` key** - Text is transcribed and automatically pasted
6. **View History** - Click the menu bar icon to access previous transcriptions

## Performance

Apple's SFSpeechRecognizer provides near-instant transcription:
- **Short recordings (1-4s):** ~0.3-0.5s transcription
- **Medium recordings (5-10s):** ~0.5-0.8s transcription
- **Long recordings (10-20s):** ~0.8-1.2s transcription

Total latency includes transcription + paste time. Significantly faster than Whisper, especially for diverse accents.

## How It Works

Hush uses Apple's native [SFSpeechRecognizer](https://developer.apple.com/documentation/speech/sfspeechrecognizer) framework for transcription.

1. **Input Monitoring:** `CGEventTap` detects `Fn` key press/release globally
2. **Audio Capture:** `AVAudioEngine` records 16kHz mono audio while key is held
3. **Transcription:** Audio processed by Apple's on-device speech recognition models
4. **Injection:** Text automatically pasted at cursor via system clipboard

## Technical Details

- **Speech Engine:** Apple SFSpeechRecognizer (on-device recognition)
- **Audio Format:** 16kHz, mono, Float32 PCM
- **Locale Support:** en-US (with excellent accent handling)
- **UI:** SwiftUI with native `.glassEffect(.clear)` material
- **Concurrency:** Swift 6 with strict concurrency checking
- **Requires:** Siri and Dictation enabled in system settings

## License

MIT License. Feel free to use, modify, and distribute.
