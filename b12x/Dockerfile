# vllm-b12x-patched: the mirrored B12X vLLM nightly (vllm-b12x:<YYYYMMDD>, see
# the mirror-b12x lane) with the fixes it is still missing, applied as patch
# files from b12x/patches/.
#
# A line of its own so the vllm-b12x mirror stays digest-identical to upstream.
# Each patch is a change upstream vLLM (or the B12X fork) has taken or is
# taking; its header links it. A patch is dropped once a nightly carries it,
# and the line goes away when none is left. The build fails when a patch no
# longer applies to the base: a bumped nightly that already carries the change
# shows up here instead of being patched twice.

# renovate: datasource=docker depName=gsoci.azurecr.io/giantswarm/vllm-b12x
FROM gsoci.azurecr.io/giantswarm/vllm-b12x:20261008@sha256:ecf04ea976f41053046f3b7db82b5424670b51929767e00bfa7a8eb499e3d6e5

COPY b12x/patches/ /tmp/giantswarm-vllm-patches/

# A directory of our own: the base image ships the B12X stack's patches under
# /tmp/b12x-patches/. The patches are relative to the vllm package's parent directory (a/vllm/...),
# found without importing vllm. Every patch is checked with --dry-run before
# any is applied, so the image is either fully patched or not built.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends patch; \
    rm -rf /var/lib/apt/lists/*; \
    root="$(python3 -c 'import importlib.util, os; print(os.path.dirname(os.path.dirname(importlib.util.find_spec("vllm").origin)))')"; \
    for p in /tmp/giantswarm-vllm-patches/*.patch; do patch -p1 -d "${root}" --forward --dry-run < "${p}"; done; \
    for p in /tmp/giantswarm-vllm-patches/*.patch; do patch -p1 -d "${root}" --forward --no-backup-if-mismatch < "${p}"; done; \
    for f in $(sed -n 's|^+++ b/\([^[:space:]]*\).*|\1|p' /tmp/giantswarm-vllm-patches/*.patch); do python3 -m py_compile "${root}/${f}"; done; \
    rm -rf /tmp/giantswarm-vllm-patches

# The base image's entrypoint (nvidia_entrypoint.sh, no default command) stays:
# the runtime supplies the whole `vllm serve …` command line, as for vllm-b12x.
