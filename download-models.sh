#!/bin/bash
set -e

MODEL_DIR=${MODEL_DIR:-/models/llamacpp-cuda-gemma-3-27b-it-q8}
mkdir -p "$MODEL_DIR"

MODEL1="$MODEL_DIR/gemma-3-27b-it-Q8_0.gguf"
MODEL2="$MODEL_DIR/mmproj-model-f16.gguf"

if [ ! -f "$MODEL1" ]; then
  echo "Downloading $MODEL1 ..."
  curl -L --fail --progress-bar \
    -o "$MODEL1" \
    https://huggingface.co/ggml-org/gemma-3-27b-it-GGUF/resolve/main/gemma-3-27b-it-Q8_0.gguf
fi

if [ ! -f "$MODEL2" ]; then
  echo "Downloading $MODEL2 ..."
  curl -L --fail --progress-bar \
    -o "$MODEL2" \
    https://huggingface.co/ggml-org/gemma-3-27b-it-GGUF/resolve/main/mmproj-model-f16.gguf
fi
