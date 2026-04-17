# vLLM image for DGX Spark (ARM64, Blackwell sm_121, 128GB unified memory)
#
# Based on NVIDIA's PyTorch container for its tested Triton, cuDNN, NCCL, and
# TransformerEngine stack (fixes the TRITON_MLA kernel crash seen with nightly
# Triton). PyTorch itself is upgraded to nightly to match the ABI expected by
# the eugr prebuilt vLLM/FlashInfer wheels.
#
# Prebuilt wheels source: https://github.com/eugr/spark-vllm-docker/releases

# renovate: datasource=docker depName=nvcr.io/nvidia/pytorch
FROM nvcr.io/nvidia/pytorch:26.03-py3

ENV UV_SYSTEM_PYTHON=1
ENV UV_BREAK_SYSTEM_PACKAGES=1
ENV UV_LINK_MODE=copy
ENV UV_HTTP_TIMEOUT=600

RUN pip install uv && \
    pip uninstall -y flash-attn

WORKDIR /workspace/vllm

# Replace NGC's patched PyTorch with the standard 2.11.0 from pytorch.org.
# The eugr vLLM wheels are compiled against standard PyTorch 2.11.0, whose
# C++ ABI differs from NGC's fork (missing register_opaque_type hoist param,
# different symbol exports for at::cuda functions).
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --reinstall \
      "torch==2.11.0" torchvision torchaudio \
      --index-url https://download.pytorch.org/whl/cu130

# Download prebuilt wheels from eugr/spark-vllm-docker GitHub releases.
# The release tags are rolling (updated nightly with tested builds).
RUN mkdir -p /tmp/wheels && \
    for tag in prebuilt-vllm-current prebuilt-flashinfer-current; do \
      curl -sf "https://api.github.com/repos/eugr/spark-vllm-docker/releases/tags/${tag}" \
        -o /tmp/release.json \
        || { echo "ERROR: failed to fetch ${tag} release metadata"; exit 1; } && \
      python3 -c "import json;[print(a['browser_download_url']) for a in json.load(open('/tmp/release.json'))['assets'] if a['name'].endswith('.whl')]" \
        > /tmp/urls.txt && \
      while IFS= read -r url; do \
        name=$(python3 -c "import urllib.parse,sys;print(urllib.parse.unquote(sys.argv[1].split('/')[-1]))" "${url}") && \
        echo "Downloading ${name}..." && \
        curl -fL --progress-bar -o "/tmp/wheels/${name}" "${url}" \
          || { echo "ERROR: failed to download ${name}"; exit 1; }; \
      done < /tmp/urls.txt; \
    done && \
    rm -f /tmp/release.json /tmp/urls.txt && \
    ls /tmp/wheels/vllm-*.whl >/dev/null 2>&1 \
      || { echo "ERROR: vllm wheel not found after download"; exit 1; } && \
    ls -lh /tmp/wheels/

RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install /tmp/wheels/*.whl && \
    rm -rf /tmp/wheels

# Mistral Small 4 (119B) requires mistral-common >= 1.10.0 for reasoning_effort
# support in the MistralCommonTokenizer, and transformers from git for the
# TokenizersBackend tokenizer class used by the mistral4 model type.
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install "mistral-common>=1.10.0" && \
    uv pip install "git+https://github.com/huggingface/transformers.git"

ENV TORCH_CUDA_ARCH_LIST="12.1a"
ENV FLASHINFER_CUDA_ARCH_LIST="12.1a"
ENV TRITON_PTXAS_PATH=/usr/local/cuda/bin/ptxas
ENV VLLM_CONFIG_ROOT=/tmp

ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
