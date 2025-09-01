# syntax=docker/dockerfile:1.7

FROM ghcr.io/darkstar1997/llamacpp-cuda:b6332

ENV NGL=100
ENV CTX=32768
ENV MODEL_DIR=/models/llamacpp-cuda-gemma-3-27b-it-q4

EXPOSE 8080

# Copy the model downloader script into the image
COPY download-models.sh /opt/llama.cpp/download-models.sh
RUN chmod +x /opt/llama.cpp/download-models.sh

CMD ["/bin/bash","-lc","/opt/llama.cpp/download-models.sh && exec /opt/llama.cpp/build/bin/llama-server -m ${MODEL_DIR}/gemma-3-27b-it-Q4_K_M.gguf --mmproj ${MODEL_DIR}/mmproj-model-f16.gguf -ngl ${NGL} --context-shift -c ${CTX} -fa on --host 0.0.0.0 --port 8080"]
