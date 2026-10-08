# vLLM image for DGX Spark (ARM64, Blackwell sm_121, 128GB unified memory)
#
# Based on NVIDIA's PyTorch container for its tested Triton, cuDNN, NCCL, and
# TransformerEngine stack (fixes the TRITON_MLA kernel crash seen with nightly
# Triton). PyTorch itself is upgraded to nightly to match the ABI expected by
# the eugr prebuilt vLLM wheel.
#
# Prebuilt vLLM wheel source: https://github.com/eugr/spark-vllm-docker/releases
# FlashInfer wheels source: https://flashinfer.ai/whl/

# renovate: datasource=docker depName=nvcr.io/nvidia/pytorch
FROM nvcr.io/nvidia/pytorch:26.09-py3

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
# NGC's patched Triton is preserved because it contains the TRITON_MLA kernel
# fix for MLA attention (FLASHINFER does not support MLA on this architecture).
RUN cp -a /usr/local/lib/python3.12/dist-packages/triton /tmp/ngc-triton && \
    cp -a /usr/local/lib/python3.12/dist-packages/triton_helpers /tmp/ngc-triton_helpers 2>/dev/null || true && \
    cp -a /usr/local/lib/python3.12/dist-packages/triton_kernels /tmp/ngc-triton_kernels 2>/dev/null || true
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --reinstall \
      "torch==2.11.0" torchvision torchaudio \
      --index-url https://download.pytorch.org/whl/cu130
RUN rm -rf /usr/local/lib/python3.12/dist-packages/triton && \
    cp -a /tmp/ngc-triton /usr/local/lib/python3.12/dist-packages/triton && \
    if [ -d /tmp/ngc-triton_helpers ]; then \
      rm -rf /usr/local/lib/python3.12/dist-packages/triton_helpers && \
      cp -a /tmp/ngc-triton_helpers /usr/local/lib/python3.12/dist-packages/triton_helpers; \
    fi && \
    if [ -d /tmp/ngc-triton_kernels ]; then \
      rm -rf /usr/local/lib/python3.12/dist-packages/triton_kernels && \
      cp -a /tmp/ngc-triton_kernels /usr/local/lib/python3.12/dist-packages/triton_kernels; \
    fi && \
    rm -rf /tmp/ngc-triton /tmp/ngc-triton_helpers /tmp/ngc-triton_kernels

# The vLLM wheel comes from the eugr/spark-vllm-docker GitHub release
# prebuilt-vllm-current (rolling, updated with tested builds). FlashInfer comes
# from its own upstream release index at the version vLLM's
# requirements/cuda.txt pins for that wheel: flashinfer-python and
# flashinfer-cubin (the cubin wheel is not on PyPI since 0.6.14). It does not
# install the FlashInfer JIT cache: since FlashInfer 0.7 that cache is a shim
# wheel (flashinfer_jit_cache) requiring a per-architecture provider wheel
# (flashinfer-jit-cache-sm121a) which no index offers for this build, and a
# provider from another build would load precompiled kernels that do not match
# the Python side. FlashInfer compiles the kernels it needs at first use into
# FLASHINFER_WORKSPACE_BASE (set below), as it does without a cache.
# See https://github.com/giantswarm/vllm/issues/68 and
# https://github.com/giantswarm/vllm/issues/93.
ARG FLASHINFER_VERSION=0.7.0.post1
RUN mkdir -p /tmp/wheels && \
    curl -sf "https://api.github.com/repos/eugr/spark-vllm-docker/releases/tags/prebuilt-vllm-current" \
      -o /tmp/release.json \
      || { echo "ERROR: failed to fetch prebuilt-vllm-current release metadata"; exit 1; } && \
    python3 -c "import json;[print(a['browser_download_url']) for a in json.load(open('/tmp/release.json'))['assets'] if a['name'].endswith('.whl') and a['name'].startswith('vllm-')]" \
      > /tmp/urls.txt && \
    while IFS= read -r url; do \
      name=$(python3 -c "import urllib.parse,sys;print(urllib.parse.unquote(sys.argv[1].split('/')[-1]))" "${url}") && \
      echo "Downloading ${name}..." && \
      curl -fL --progress-bar -o "/tmp/wheels/${name}" "${url}" \
        || { echo "ERROR: failed to download ${name}"; exit 1; }; \
    done < /tmp/urls.txt && \
    rm -f /tmp/release.json /tmp/urls.txt && \
    ls /tmp/wheels/vllm-*.whl >/dev/null 2>&1 \
      || { echo "ERROR: vllm-*.whl not found after download"; exit 1; } && \
    pip download --no-deps --dest /tmp/wheels \
      --index-url https://flashinfer.ai/whl/ --extra-index-url https://pypi.org/simple \
      "flashinfer-python==${FLASHINFER_VERSION}" "flashinfer-cubin==${FLASHINFER_VERSION}" && \
    ls -lh /tmp/wheels/

# quack-kernels lags one CUTLASS DSL release behind vLLM (e.g. quack-kernels
# 0.6.4 pins nvidia-cutlass-dsl==4.6.2 while the vLLM wheel wants
# [cu13]==4.7.0), which makes the joint resolve unsatisfiable. Mirror upstream
# spark-vllm-docker: override that transitive constraint with whatever CUTLASS
# DSL pin the vLLM wheel itself declares, so the rolling wheel stays
# self-consistent on every nightly.
RUN --mount=type=cache,target=/root/.cache/uv \
    python3 -c "import glob,zipfile;\
z=zipfile.ZipFile(glob.glob('/tmp/wheels/vllm-*.whl')[0]);\
meta=[n for n in z.namelist() if n.endswith('.dist-info/METADATA')][0];\
[print(l.split(':',1)[1].split(';')[0].strip()) for l in z.read(meta).decode().splitlines() if l.startswith('Requires-Dist: nvidia-cutlass-dsl')]" \
      > /tmp/wheel-override.txt && \
    echo "uv overrides:" && cat /tmp/wheel-override.txt && \
    uv pip install --overrides /tmp/wheel-override.txt /tmp/wheels/*.whl && \
    rm -rf /tmp/wheels /tmp/wheel-override.txt

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
# FlashInfer compiles kernels at first use (no precompiled JIT cache, see the
# wheel download above) and writes them under
# $FLASHINFER_WORKSPACE_BASE/.cache/flashinfer. /tmp is writable for root and
# for a non-root uid on a read-only root filesystem alike, like VLLM_CONFIG_ROOT.
ENV FLASHINFER_WORKSPACE_BASE=/tmp

ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
