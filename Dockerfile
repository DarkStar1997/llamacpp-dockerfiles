# syntax=docker/dockerfile:1.7

############################
# 1) Build stage
############################
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG LLAMA_CPP_TAG=b6332
ARG CUDAARCHS="100;90;89;86;80;75"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates build-essential cmake ninja-build \
    libopenblas-dev pkg-config libcurl4-openssl-dev curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone -b "${LLAMA_CPP_TAG}" --depth 1 https://github.com/ggerganov/llama.cpp.git
WORKDIR /opt/llama.cpp

ENV CUDA_STUBS=/usr/local/cuda/targets/x86_64-linux/lib/stubs
RUN ln -sf ${CUDA_STUBS}/libcuda.so /usr/lib/x86_64-linux-gnu/libcuda.so.1

RUN cmake -S . -B build -G Ninja \
      -DGGML_CUDA=ON \
      -DGGML_NATIVE=ON \
      -DGGML_BLAS=ON \
      -DGGML_BLAS_VENDOR=OpenBLAS \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CUDA_ARCHITECTURES="${CUDAARCHS}" \
      -DCMAKE_EXE_LINKER_FLAGS="-Wl,-rpath-link,${CUDA_STUBS}" \
      -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath-link,${CUDA_STUBS}" \
    && cmake --build build -j"$(nproc)"

############################
# 2) Runtime stage
############################
FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04 AS runtime

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libstdc++6 libgcc-s1 libgomp1 \
    libopenblas0 libcurl4 curl \
    && rm -rf /var/lib/apt/lists/*

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

COPY --from=builder /opt/llama.cpp/build/bin/ /opt/llama.cpp/build/bin/

RUN mkdir -p /opt/llama.cpp/models && \
    curl -L --fail --progress-bar \
      -o /opt/llama.cpp/models/gemma-3-27b-it-Q4_K_M.gguf \
      https://huggingface.co/ggml-org/gemma-3-27b-it-GGUF/resolve/main/gemma-3-27b-it-Q4_K_M.gguf && \
    curl -L --fail --progress-bar \
      -o /opt/llama.cpp/models/mmproj-model-f16.gguf \
      https://huggingface.co/ggml-org/gemma-3-27b-it-GGUF/resolve/main/mmproj-model-f16.gguf

ENV NGL=100
ENV CTX=32768

# Expose server port
EXPOSE 8080

# Run llama-server with Gemma model and overridable ngl/ctx
CMD ["/bin/bash", "-lc", "/opt/llama.cpp/build/bin/llama-server -m /opt/llama.cpp/models/gemma-3-27b-it-Q4_K_M.gguf --mmproj /opt/llama.cpp/models/mmproj-model-f16.gguf -ngl ${NGL} --context-shift -c ${CTX} -fa on --host 0.0.0.0 --port 8080"]
