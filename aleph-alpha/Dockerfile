# vLLM image for Aleph Alpha's models (Kolibri-1): vLLM's own server image with
# Aleph Alpha's aleph-alpha-inference plugin, which registers the kolibri1
# architecture and its reasoning and tool-call parsers.
#
# A line of its own beside ../Dockerfile: each plugin release supports exactly
# one vLLM minor (1.0.0: vllm>=0.29.0,<0.30.0), while the main image follows
# the rolling nightlies. Base and plugin move together (renovate-custom.json5
# holds the base below 0.30.0). Aleph Alpha's own image of the same recipe is
# amd64 only; this one is built for the arm64 GB10 nodes.
#
# Upstream recipe: https://github.com/Aleph-Alpha/aleph-alpha-inference/blob/main/Dockerfile

# renovate: datasource=docker depName=vllm/vllm-openai
FROM vllm/vllm-openai:v0.31.0@sha256:c1c9f6fd5c109ba7f0546a59f5b2f15fb87f64c77782e90a27b648b42a8e67c3

# --no-deps: the base image already has the vllm, torch and transformers the
# plugin release supports, and pip must not replace them. The wheel is pinned
# by hash.
COPY aleph-alpha/requirements.txt /tmp/aleph-alpha-requirements.txt
RUN pip install --no-cache-dir --no-deps --require-hashes \
      -r /tmp/aleph-alpha-requirements.txt && \
    rm /tmp/aleph-alpha-requirements.txt && \
    python3 -c "import aleph_alpha_inference"

# The base image's entrypoint stays `vllm serve`, so the image is used like
# vllm/vllm-openai: <image> <model> [vllm serve options].
