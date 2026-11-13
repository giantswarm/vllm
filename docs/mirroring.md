# Mirroring upstream ARM64 images

The `mirror-nightly` workflow in [`.circleci/custom.yml`](../.circleci/custom.yml)
copies upstream nightlies to gsoci and signs their digests. It runs three jobs:

| Job | Upstream | Destination |
| --- | --- | --- |
| `mirror-eugr` | `ghcr.io/spark-arena/dgx-vllm-eugr-nightly` | `gsoci.azurecr.io/giantswarm/vllm:eugr-<YYYYMMDDNN>` and `eugr-latest` |
| `mirror-eugr-tf5` | `ghcr.io/spark-arena/dgx-vllm-eugr-nightly-tf5` | `gsoci.azurecr.io/giantswarm/vllm:eugr-tf5-<YYYYMMDDNN>` and `eugr-tf5-latest` |
| `mirror-b12x` | `docker.io/eugr/spark-vllm-b12x:nightly-<YYYYMMDD>` | `gsoci.azurecr.io/giantswarm/vllm-b12x:<YYYYMMDD>` |

The eugr jobs resolve `latest` to an upstream date-revision tag with the same
digest. B12X selects the newest dated nightly and has no floating alias.

## Inspection on the amd64 executor

Both mirror implementations run on the architect orb's amd64 executor. An
upstream index can contain only ARM64 images, so skopeo's default host-platform
selection fails even though the index exists. Every source, candidate-tag and
destination inspection explicitly selects `linux/arm64`:

```sh
skopeo --override-os linux --override-arch arm64 inspect --no-tags \
  --format '{{.Digest}}' "docker://${IMAGE_REF}"
```

The override selects the image whose platform metadata skopeo inspects. The
reported `.Digest` remains the top-level index digest for an indexed image;
it is not replaced with the selected ARM64 child-manifest digest. For a source
that is a single manifest, it is that manifest's digest.

## Preserve and sign the complete index

Copies use `skopeo copy --all --preserve-digests --retry-times 5`, with the source
pinned by the inspected digest. `--all` copies the complete index and its child
images, including any other platforms. The inspection override does not narrow
the copy to one platform. `--preserve-digests` prevents a successful copy from
silently changing the manifests or index.

The jobs skip a pinned copy already at the source digest, then inspect the
pinned destination and fail on a digest mismatch. The eugr jobs also copy the
pinned tag to its floating alias with the same preservation flags.

Only after the destination digest check passes does the job record
`<destination-repository>@<source-digest>` for signing. The shared
`sign-mirrored-digest` command verifies this exact reference with the CircleCI
OIDC issuer and identity pattern. A valid existing signature is reused; a
missing signature is staged for the architect orb's `cosign-sign-verify`.
Other verification errors fail the job. Signatures cover the top-level digest,
so aliases pointing at that digest share its signature.

## Verify after merge

Push and tag pipelines exclude `mirror-nightly`. Green PR CI therefore does
not prove a successful registry copy or signature. After merge:

1. Use a scheduled pipeline on `main`, or an on-demand API-triggered pipeline
   as described in [Mirror schedule](../README.md#mirror-schedule). Confirm
   its revision contains the merged change and that `mirror-eugr`,
   `mirror-eugr-tf5` and `mirror-b12x` all run and succeed.
2. Record each job's resolved upstream date tag and source digest. Inspect the
   pinned source and destination using the explicit ARM64 selection above;
   compare their top-level digests. For indexed images, inspect the raw
   indexes with `skopeo inspect --raw` and confirm their complete descriptor
   lists match. Check both eugr floating aliases resolve to their pinned
   destination digests too. Use the resolved date tags, since upstream
   `latest` can move during verification.
3. Verify each destination by digest with the same identity policy as the job:

   ```sh
   cosign verify \
     --certificate-oidc-issuer-regexp '^https://oidc\.circleci\.com' \
     --certificate-identity-regexp '^https://circleci\.com/api/v2/projects/[a-f0-9-]+/pipeline-definitions/[a-f0-9-]+$' \
     "${DESTINATION_REPO}@${SOURCE_DIGEST}"
   ```

4. Record the pipeline revision, workflow/job links, resolved tags, matching
   digests and signature results in the tracking issue. Distinguish a fresh
   copy/sign from a run that reused an existing digest/signature; a skip does
   not exercise a new upload. Also verify any release produced by the merge
   through its tag pipeline and published artifacts: the nightly mirrors and
   the semver release are separate workflows.

Mirror verification establishes artifact integrity and signing. Model startup,
chat completion and preset rollout require their own serving proof.
