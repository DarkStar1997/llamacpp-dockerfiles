# syntax=docker/dockerfile:1.7

FROM ghcr.io/darkstar1997/llamacpp-cuda:b6332

RUN mkdir -p /opt/llama.cpp/models && \
    curl -L --fail --progress-bar \
      -o /opt/llama.cpp/models/gemma-3-27b-it-Q4_K_M.gguf \
      https://huggingface.co/ggml-org/gemma-3-27b-it-GGUF/resolve/main/gemma-3-27b-it-Q4_K_M.gguf && \
    curl -L --fail --progress-bar \
      -o /opt/llama.cpp/models/mmproj-model-f16.gguf \
      https://huggingface.co/ggml-org/gemma-3-27b-it-GGUF/resolve/main/mmproj-model-f16.gguf

ENV NGL=100
ENV CTX=32768

EXPOSE 8080

CMD ["/bin/bash", "-lc", "/opt/llama.cpp/build/bin/llama-server -m /opt/llama.cpp/models/gemma-3-27b-it-Q4_K_M.gguf --mmproj /opt/llama.cpp/models/mmproj-model-f16.gguf -ngl ${NGL} --context-shift -c ${CTX} -fa on --host 0.0.0.0 --port 8080"]
