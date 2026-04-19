# vllm

Giant Swarm build of [vLLM](https://github.com/vllm-project/vllm) for ARM64 (DGX Spark with Blackwell GPUs). Produces:

- **Container image**: `gsoci.azurecr.io/giantswarm/vllm` (ARM64 only)

The image is used as a KServe predictor via a `ClusterServingRuntime`. It exposes an OpenAI-compatible API at `:8080/v1`.

## Image variants on `gsoci.azurecr.io/giantswarm/vllm`

| Tag pattern | Source | Used for |
|---|---|---|
| `<semver>` (e.g. `0.3.3`) | This repo's `Dockerfile` (CircleCI tag build, NGC PyTorch + eugr wheels) | Existing single-image runtime (`bwi-kserve-vllm`, `kserve-vllm`) |
| `eugr-<YYYYMMDDNN>` | Mirror of `ghcr.io/spark-arena/dgx-vllm-eugr-nightly:<tag>` | Spark-arena recipe-driven InferenceServices that need eugr-only parsers / flags |
| `eugr-tf5-<YYYYMMDDNN>` | Mirror of `ghcr.io/spark-arena/dgx-vllm-eugr-nightly-tf5:<tag>` | Same, for models that require the `transformers from git` (`-tf5`) variant |
| `eugr-latest`, `eugr-tf5-latest` | Floating alias re-tagged on each successful mirror run | Convenience for development; production should pin to a date tag |

The semver tags are produced by the `build` workflow on git tag pushes (see `Updating` below). The `eugr-*` tags are produced by the `mirror-spark-arena-nightly` workflow in `.circleci/config.yml`, which uses the `architect` CircleCI context (`ACR_GSOCI_USERNAME` / `ACR_GSOCI_PASSWORD`) to push to `gsoci.azurecr.io/giantswarm/vllm`. The mirror runs daily at 06:00 UTC; an on-demand run is just a re-run of `mirror-spark-arena-nightly` from the CircleCI UI on `main`.

The mirror job resolves the upstream `latest` (or an explicit `source_tag` parameter) to a digest, walks recent 10-digit upstream `YYYYMMDDNN` tags to find the one pointing at that digest, and copies the upstream blobs to `gsoci.azurecr.io/giantswarm/vllm:<prefix>-<YYYYMMDDNN>`. The pinned-tag copy is skipped when the destination already holds the same digest, so re-runs are cheap. The `eugr-latest` / `eugr-tf5-latest` aliases are always re-pointed at the just-mirrored pinned tag.

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
