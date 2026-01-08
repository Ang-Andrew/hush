#!/bin/bash

# Directory setup
MODEL_DIR="$HOME/.hush/models"
mkdir -p "$MODEL_DIR"

echo "📂 Set up model directory at $MODEL_DIR"

# URLs for Hugging Face (ggerganov/whisper.cpp)
BASE_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main"

# 1. Download the Base English Model (CPU Decoder)
if [ ! -f "$MODEL_DIR/ggml-base.en.bin" ]; then
    echo "⬇️  Downloading Base (En) Model (148 MB)..."
    curl -L "$BASE_URL/ggml-base.en.bin" -o "$MODEL_DIR/ggml-base.en.bin"
else
    echo "✅ Base Model already exists."
fi

# 2. Download the CoreML Encoder (ANE Accelerator)
if [ ! -d "$MODEL_DIR/ggml-base.en-encoder.mlmodelc" ]; then
    echo "⬇️  Downloading CoreML Encoder (38 MB)..."
    curl -L "$BASE_URL/ggml-base.en-encoder.mlmodelc.zip" -o "$MODEL_DIR/coreml.zip"
    
    echo "📦 Unzipping CoreML Encoder..."
    unzip -o "$MODEL_DIR/coreml.zip" -d "$MODEL_DIR"
    rm "$MODEL_DIR/coreml.zip"
else
    echo "✅ CoreML Encoder already exists."
fi

echo "🎉 Setup Complete! Models are ready for Hush."
