# vllm

Giant Swarm build of [vLLM](https://github.com/vllm-project/vllm) for ARM64 (DGX Spark with Blackwell GPUs). Produces:

- **Container image**: `gsoci.azurecr.io/giantswarm/vllm` (ARM64 only)

The image is used as a KServe predictor via a `ClusterServingRuntime`. It exposes an OpenAI-compatible API at `:8080/v1`.

## How it works

The Dockerfile does **not** build vLLM from source. Instead it:

1. Starts from `nvidia/cuda:13.2.0-devel-ubuntu24.04`
2. Installs PyTorch nightly from the `cu130` index
3. Downloads prebuilt vLLM + FlashInfer wheels from [eugr/spark-vllm-docker](https://github.com/eugr/spark-vllm-docker/releases) (compiled for CUDA 13.2 / Blackwell sm_121)
4. Installs Mistral runtime dependencies (`mistral-common >= 1.10.0`, `transformers` from git)

The prebuilt wheels use rolling release tags (`prebuilt-vllm-current`, `prebuilt-flashinfer-current`) that are updated nightly with tested builds.

## Target hardware

- **Architecture**: ARM64 (aarch64)
- **GPU**: NVIDIA Blackwell (sm_121) -- `TORCH_CUDA_ARCH_LIST=12.1a`
- **CUDA**: 13.2

## Updating

Renovate tracks the CUDA base image version. The prebuilt wheels auto-update on each build since they use rolling release tags.

To rebuild manually, create a new tag:

```bash
git tag v0.x.0
git push origin v0.x.0
```

## Local build

```bash
docker buildx build --platform linux/arm64 -t vllm:dev .
```
