# vllm

Giant Swarm build of [vLLM](https://github.com/vllm-project/vllm) for ARM64 (DGX Spark with Blackwell GPUs). Produces:

- **Container image**: `gsoci.azurecr.io/giantswarm/vllm` (ARM64 only)
- **Helm chart**: `oci://gsoci.azurecr.io/charts/giantswarm/vllm` (ships the `bwi-kserve-vllm`, `bwi-vllm`, `bwi-vllm-tf5` `ClusterServingRuntime` manifests; see [`helm/vllm/README.md`](./helm/vllm/README.md))
- **Signed mirrors** of upstream vLLM nightlies for ARM64 Blackwell nodes: `gsoci.azurecr.io/giantswarm/vllm:eugr-*` and `gsoci.azurecr.io/giantswarm/vllm-b12x` (see [Images on gsoci](#images-on-gsoci))

The image is used as a KServe predictor via a `ClusterServingRuntime`. It exposes an OpenAI-compatible API at `:8080/v1`. The chart is referenced as the `vllm-runtime` per-app component of the BWI OCM bundle in `giantswarm/bwi` so every per-app component in that bundle is a chart + image combination.

## Images on gsoci

| Image and tag | Source | Used for |
|---|---|---|
| `vllm:<semver>` (e.g. `0.3.3`) | This repo's `Dockerfile` (CircleCI tag build, NGC PyTorch + eugr wheels) | Existing single-image runtime (`bwi-kserve-vllm`, `kserve-vllm`) |
| `vllm:eugr-<YYYYMMDDNN>` | Mirror of `ghcr.io/spark-arena/dgx-vllm-eugr-nightly:<YYYYMMDDNN>` | Spark-arena recipe-driven InferenceServices that need eugr-only parsers / flags |
| `vllm:eugr-tf5-<YYYYMMDDNN>` | Mirror of `ghcr.io/spark-arena/dgx-vllm-eugr-nightly-tf5:<YYYYMMDDNN>` | Same, for models that require the `transformers from git` (`-tf5`) variant |
| `vllm:eugr-latest`, `vllm:eugr-tf5-latest` | Floating alias re-tagged on each successful mirror run | Convenience for development; production pins a date tag |
| `vllm-b12x:<YYYYMMDD>` | Mirror of `docker.io/eugr/spark-vllm-b12x:nightly-<YYYYMMDD>` (linux/arm64, digest-identical) | The B12X vLLM stack that serves NVFP4 quantization-aware-distilled models on ARM64 unified-memory Blackwell nodes (GB10) -- the `kserve-vllm-b12x` runtime the `qwen3-8-flash-next-nvfp4` preset of [giantswarm/agent-platform](https://github.com/giantswarm/agent-platform) selects. The entrypoint runs `vllm serve`, so a runtime passes serve arguments only. The image `mlock()`s every weight allocation: the node's containerd needs `LimitMEMLOCK=infinity`, or the server dies at start under the 8 MB default ([giantswarm/agent-platform#564](https://github.com/giantswarm/agent-platform/issues/564)). No floating alias: pin a date tag and let Renovate bump it (`docker` datasource on gsoci). |

The semver tags are produced by the `build` workflow on git tag pushes (see `Updating` below). The mirrored tags are produced by the `mirror-nightly` workflow in `.circleci/custom.yml`, which uses the `architect` CircleCI context (`ACR_GSOCI_USERNAME` / `ACR_GSOCI_PASSWORD`) to push to gsoci. Each lane is a job of its own, so one failing leaves the others intact:

- `mirror-eugr` / `mirror-eugr-tf5` resolve the upstream `latest` to a digest, walk recent 10-digit upstream `YYYYMMDDNN` tags to find the one pointing at that digest, and copy the upstream blobs to `vllm:<prefix>-<YYYYMMDDNN>`. The `eugr-latest` / `eugr-tf5-latest` aliases are re-pointed at the just-mirrored pinned tag.
- `mirror-b12x` picks the newest upstream `nightly-<YYYYMMDD>` tag by its date and copies it to `vllm-b12x:<YYYYMMDD>`.

Every copy is `skopeo copy --all --preserve-digests`: the digest on gsoci is the upstream digest, and the job fails if it is not. A copy is skipped when the destination already holds the same digest, so re-runs are cheap. Mirrored tags are never deleted.

### Signatures

Every mirrored digest is signed with cosign keyless under the mirror job's CircleCI OIDC identity (a Fulcio certificate, an entry in the public Rekor transparency log) through the architect orb's `cosign-sign-verify` command -- the same command, issuer and identity pattern the orb applies to the images it builds. An image built by a Giant Swarm CircleCI project and an image mirrored by one therefore verify with the same attestor, and one Kyverno `verifyImages` rule admits both. The signature is attached to the digest, so the `eugr-*-latest` aliases are covered by the signature of the pinned tag they point at. A digest that already verifies is not signed again on a re-run.

```bash
cosign verify \
  --certificate-oidc-issuer https://oidc.circleci.com \
  --certificate-identity-regexp '^https://circleci\.com/api/v2/projects/[a-f0-9-]+/pipeline-definitions/[a-f0-9-]+$' \
  gsoci.azurecr.io/giantswarm/vllm-b12x:<YYYYMMDD>
```

### Mirror schedule

The mirror workflow runs on every pipeline of `main` that is not a git push: the daily schedule and on-demand API triggers. It never runs on pushes or tags. The schedule is a CircleCI [Scheduled Pipeline](https://circleci.com/docs/scheduled-pipelines/) named `mirror-nightly` on this project (06:00 UTC, branch `main`); a legacy `triggers: schedule` inside `.circleci/custom.yml` is never evaluated, because CircleCI reads cron triggers from the setup config only and the setup config is generated. The schedule runs as a project member (the `architect` context is restricted to members, which the neutral system actor cannot use); re-create it when that member leaves.

```bash
# Inspect the schedule.
curl -s -H "Circle-Token: $CIRCLE_TOKEN" https://circleci.com/api/v2/project/gh/giantswarm/vllm/schedule | jq '.items[] | {name, timetable, actor: .actor.login}'

# Create it (once, by a project member).
curl -s -X POST -H "Circle-Token: $CIRCLE_TOKEN" -H 'Content-Type: application/json' \
  https://circleci.com/api/v2/project/gh/giantswarm/vllm/schedule \
  -d '{"name":"mirror-nightly","description":"Daily mirror and signature of the upstream vLLM nightlies onto gsoci (.circleci/custom.yml, workflow mirror-nightly).","attribution-actor":"current","parameters":{"branch":"main"},"timetable":{"per-hour":1,"hours-of-day":[6],"days-of-week":["MON","TUE","WED","THU","FRI","SAT","SUN"]}}'

# Run the mirror lanes now.
curl -s -X POST -H "Circle-Token: $CIRCLE_TOKEN" -H 'Content-Type: application/json' \
  https://circleci.com/api/v2/project/gh/giantswarm/vllm/pipeline -d '{"branch":"main"}'
```

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
