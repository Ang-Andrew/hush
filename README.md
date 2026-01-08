# Hush 🤫

**Hush** is a lightning-fast, privacy-first voice dictation tool for macOS. Inspired by Wispr Flow, it allows you to speak into any text field simply by holding the `Fn` key. 

Everything happens locally on your device using the Apple Neural Engine—no audio is ever sent to the cloud.

![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%2014+-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## Features

- **⚡️ Instant Dictation:** Hold `Fn` to capture, release to transcribe. Text appears instantly.
- **🔒 Private & Local:** All inference runs on-device using `whisper.cpp` and CoreML. Your voice data never leaves your machine.
- **🍎 Native & Lightweight:** Built in pure Swift & SwiftUI. Optimized for Apple Silicon (M1/M2/M3) for negligible battery impact.
- **📝 Universal:** Works in ANY application—Notes, VS Code, Browser, Slack, Terminal, etc.
- **📋 Clipboard Integration:** Automatically injects transcribed text via system clipboard emulation.

## Requirements

- **macOS:** 14.0 (Sonoma) or higher.
- **Hardware:** Apple Silicon (M1/M2/M3) recommended for best performance (CoreML acceleration).
- **Permissions:** 
  - Accessibility (to listen for the `Fn` key).
  - Microphone (to listen to you).

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/hush.git
cd hush
```

### 2. Download Models
Hush requires the Whisper model weights to function. We've provided a helper script to set this up automatically.

```bash
chmod +x setup_models.sh
./setup_models.sh
```
This will download the `base.en` model and its CoreML encoder to `~/.hush/models`.

### 3. Build & Run
You can run the app directly via Swift Package Manager:

```bash
swift run Hush
```

*Note: On the first run, macOS will prompt you to grant Accessibility and Microphone permissions. You may need to restart the app after granting Accessibility access.*

## Usage

1. **Launch Hush.** You'll see a menu bar icon indicating it's ready.
2. **Place your cursor** in any text input field (e.g., a text message, code editor, or sticky note).
3. **Press and HOLD the `Fn` (Function) key.**
4. **Speak** your thought.
5. **Release the `Fn` key.**
6. Watch as your speech is magically converted to text and pasted right where your cursor is!

## How It Works

Hush uses [whisper.cpp](https://github.com/ggerganov/whisper.cpp), a high-performance port of OpenAI's Whisper model. 

1. **Input Monitoring:** A low-level `CGEventTap` listens for global key events to detect the `Fn` key state.
2. **Audio Capture:** `AVAudioEngine` captures raw PCM audio while the key is held.
3. **Inference:** The audio is processed locally on the Apple Neural Engine via CoreML.
4. **Injection:** The transcription is copied to your clipboard and potential pasted using a simulated `Cmd+V` event.

## License

MIT License. Feel free to use, modify, and distribute.
