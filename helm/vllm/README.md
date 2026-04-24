# vllm

Helm chart that ships KServe `ClusterServingRuntime` manifests for the Giant
Swarm vLLM image (`gsoci.azurecr.io/giantswarm/vllm`) on DGX Spark / Blackwell
hardware. The chart is the packaging boundary the BWI OCM bundle references
(see `architecture/bwi.md` in `giantswarm/bwi`); each runtime can be toggled
independently via values flags so the same chart serves both today's
single-image deployment and the spark-arena recipe-driven variants.

## Runtimes

| Name | Source image | Default | Used for |
|---|---|---|---|
| `bwi-kserve-vllm` | This repo's Dockerfile (NGC PyTorch + eugr wheels), tag tracks chart `appVersion` | autoSelect | Models that don't need spark-arena's eugr-only parsers / flags |
| `bwi-vllm` | Mirror of `ghcr.io/spark-arena/dgx-vllm-eugr-nightly`, tag pinned to `eugr-<YYYYMMDDNN>` | opt-in via `spec.predictor.model.runtime` | Spark-arena recipe registry models |
| `bwi-vllm-tf5` | Mirror of `ghcr.io/spark-arena/dgx-vllm-eugr-nightly-tf5`, tag pinned to `eugr-tf5-<YYYYMMDDNN>` | opt-in via `spec.predictor.model.runtime` | Models that need `transformers from git` (GLM-4.7-Flash, Gemma 4) |

The spark-arena runtimes require `command: [vllm, serve]` because the upstream
nightly is built on NVIDIA NGC's PyTorch base whose `ENTRYPOINT` swallows the
container `args:` block otherwise. The legacy single-image runtime bakes the
entrypoint into the Dockerfile so it doesn't need the override.

All runtimes carry the `app.kubernetes.io/part-of: bwi-backstage` label
(configurable via `partOfLabel`) so the BWI cluster's
`bwi-clusterservingruntime` `ValidatingWebhookConfiguration` selects on them
without intercepting non-BWI runtimes cluster-wide.

## Image / chart versioning

`Chart.yaml#version` and `Chart.yaml#appVersion` are both templated as
`[[ .Version ]]` and substituted by the architect orb's
`helm template --tag-build` step at chart-build time, so a `v0.x.y` git tag
produces a chart with `version: 0.x.y` and `appVersion: 0.x.y` that bundles
the matching `bwi-kserve-vllm` image (mirrors the muster pattern). Spark-arena
variants pin their own date-rev mirror tags via
`runtimes.sparkArena.<variant>.tag` because they track the upstream
`mirror-spark-arena-nightly` cadence rather than this repo's release tags.

The chart is published as an OCI artifact at
`oci://gsoci.azurecr.io/charts/giantswarm/vllm` by the `build-vllm-chart`
CircleCI job on every `v*` tag.

For local helm CLI use (`helm lint`, `helm template`), run `make helm-lint` /
`make helm-template` -- those targets stage the chart into `build/vllm/` with
a stub `0.0.0` version substituted in so the Helm CLI doesn't trip on the
template placeholders.

## Values

See `values.yaml`. The most common overrides:

- `image.tag` -- pin a different `bwi-kserve-vllm` image (e.g. for testing a
  new build before bumping the chart).
- `runtimes.vllm.enabled: false` -- skip the legacy runtime when the cluster
  only needs the spark-arena variants.
- `runtimes.sparkArena.eugr.tag` / `runtimes.sparkArena.tf5.tag` -- bump the
  date-rev mirror tag without rebuilding the chart.
- `runtimes.sparkArena.enabled: false` -- skip both spark-arena variants.
