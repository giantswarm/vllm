# vllm

A Helm chart for vLLM ClusterServingRuntimes (DGX Spark / Blackwell)

**Homepage:** <https://github.com/giantswarm/vllm>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Giant Swarm | <support@giantswarm.io> |  |

## Source Code

* <https://github.com/giantswarm/vllm>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.registry | string | `"gsoci.azurecr.io"` |  |
| image.repository | string | `"giantswarm/vllm"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.tag | string | `""` |  |
| partOfLabel | string | `"bwi-backstage"` |  |
| runtimes.vllm.enabled | bool | `true` |  |
| runtimes.vllm.name | string | `"bwi-kserve-vllm"` |  |
| runtimes.vllm.autoSelect | bool | `true` |  |
| runtimes.vllm.priority | int | `2` |  |
| runtimes.vllm.imagePullSecrets | list | `[]` |  |
| runtimes.vllm.args[0] | string | `"--model"` |  |
| runtimes.vllm.args[1] | string | `"/mnt/models"` |  |
| runtimes.vllm.args[2] | string | `"--port"` |  |
| runtimes.vllm.args[3] | string | `"8080"` |  |
| runtimes.vllm.args[4] | string | `"--served-model-name"` |  |
| runtimes.vllm.args[5] | string | `"bwi-active"` |  |
| runtimes.vllm.args[6] | string | `"{{.Name}}"` |  |
| runtimes.vllm.args[7] | string | `"--trust-remote-code"` |  |
| runtimes.vllm.env[0].name | string | `"HF_HUB_ENABLE_HF_TRANSFER"` |  |
| runtimes.vllm.env[0].value | string | `"1"` |  |
| runtimes.vllm.env[1].name | string | `"HF_XET_HIGH_PERFORMANCE"` |  |
| runtimes.vllm.env[1].value | string | `"1"` |  |
| runtimes.vllm.env[2].name | string | `"VLLM_CONFIG_ROOT"` |  |
| runtimes.vllm.env[2].value | string | `"/tmp"` |  |
| runtimes.vllm.resources.requests.cpu | string | `"2"` |  |
| runtimes.vllm.resources.requests.memory | string | `"24Gi"` |  |
| runtimes.vllm.resources.limits.cpu | string | `"8"` |  |
| runtimes.vllm.resources.limits.memory | string | `"64Gi"` |  |
| runtimes.vllm.startupProbe.httpGet.path | string | `"/health"` |  |
| runtimes.vllm.startupProbe.httpGet.port | int | `8080` |  |
| runtimes.vllm.startupProbe.initialDelaySeconds | int | `300` |  |
| runtimes.vllm.startupProbe.periodSeconds | int | `30` |  |
| runtimes.vllm.startupProbe.failureThreshold | int | `360` |  |
| runtimes.vllm.shmSize | string | `"16Gi"` |  |
| runtimes.sparkArena.enabled | bool | `true` |  |
| runtimes.sparkArena.eugr.enabled | bool | `true` |  |
| runtimes.sparkArena.eugr.name | string | `"bwi-vllm"` |  |
| runtimes.sparkArena.eugr.tag | string | `"eugr-2026041801"` |  |
| runtimes.sparkArena.eugr.args[0] | string | `"--model"` |  |
| runtimes.sparkArena.eugr.args[1] | string | `"/mnt/models"` |  |
| runtimes.sparkArena.eugr.args[2] | string | `"--port"` |  |
| runtimes.sparkArena.eugr.args[3] | string | `"8080"` |  |
| runtimes.sparkArena.eugr.args[4] | string | `"--served-model-name"` |  |
| runtimes.sparkArena.eugr.args[5] | string | `"bwi-active"` |  |
| runtimes.sparkArena.eugr.args[6] | string | `"{{.Name}}"` |  |
| runtimes.sparkArena.eugr.args[7] | string | `"--trust-remote-code"` |  |
| runtimes.sparkArena.eugr.env[0].name | string | `"HF_HUB_ENABLE_HF_TRANSFER"` |  |
| runtimes.sparkArena.eugr.env[0].value | string | `"1"` |  |
| runtimes.sparkArena.eugr.env[1].name | string | `"HF_XET_HIGH_PERFORMANCE"` |  |
| runtimes.sparkArena.eugr.env[1].value | string | `"1"` |  |
| runtimes.sparkArena.eugr.env[2].name | string | `"VLLM_CONFIG_ROOT"` |  |
| runtimes.sparkArena.eugr.env[2].value | string | `"/tmp"` |  |
| runtimes.sparkArena.eugr.resources.requests.cpu | string | `"2"` |  |
| runtimes.sparkArena.eugr.resources.requests.memory | string | `"24Gi"` |  |
| runtimes.sparkArena.eugr.resources.limits.cpu | string | `"8"` |  |
| runtimes.sparkArena.eugr.resources.limits.memory | string | `"64Gi"` |  |
| runtimes.sparkArena.eugr.startupProbe.httpGet.path | string | `"/health"` |  |
| runtimes.sparkArena.eugr.startupProbe.httpGet.port | int | `8080` |  |
| runtimes.sparkArena.eugr.startupProbe.initialDelaySeconds | int | `300` |  |
| runtimes.sparkArena.eugr.startupProbe.periodSeconds | int | `30` |  |
| runtimes.sparkArena.eugr.startupProbe.failureThreshold | int | `360` |  |
| runtimes.sparkArena.eugr.shmSize | string | `"16Gi"` |  |
| runtimes.sparkArena.tf5.enabled | bool | `true` |  |
| runtimes.sparkArena.tf5.name | string | `"bwi-vllm-tf5"` |  |
| runtimes.sparkArena.tf5.tag | string | `"eugr-tf5-2026042101"` |  |
| runtimes.sparkArena.tf5.args[0] | string | `"--model"` |  |
| runtimes.sparkArena.tf5.args[1] | string | `"/mnt/models"` |  |
| runtimes.sparkArena.tf5.args[2] | string | `"--port"` |  |
| runtimes.sparkArena.tf5.args[3] | string | `"8080"` |  |
| runtimes.sparkArena.tf5.args[4] | string | `"--served-model-name"` |  |
| runtimes.sparkArena.tf5.args[5] | string | `"bwi-active"` |  |
| runtimes.sparkArena.tf5.args[6] | string | `"{{.Name}}"` |  |
| runtimes.sparkArena.tf5.args[7] | string | `"--trust-remote-code"` |  |
| runtimes.sparkArena.tf5.env[0].name | string | `"HF_HUB_ENABLE_HF_TRANSFER"` |  |
| runtimes.sparkArena.tf5.env[0].value | string | `"1"` |  |
| runtimes.sparkArena.tf5.env[1].name | string | `"HF_XET_HIGH_PERFORMANCE"` |  |
| runtimes.sparkArena.tf5.env[1].value | string | `"1"` |  |
| runtimes.sparkArena.tf5.env[2].name | string | `"VLLM_CONFIG_ROOT"` |  |
| runtimes.sparkArena.tf5.env[2].value | string | `"/tmp"` |  |
| runtimes.sparkArena.tf5.resources.requests.cpu | string | `"2"` |  |
| runtimes.sparkArena.tf5.resources.requests.memory | string | `"24Gi"` |  |
| runtimes.sparkArena.tf5.resources.limits.cpu | string | `"8"` |  |
| runtimes.sparkArena.tf5.resources.limits.memory | string | `"64Gi"` |  |
| runtimes.sparkArena.tf5.startupProbe.httpGet.path | string | `"/health"` |  |
| runtimes.sparkArena.tf5.startupProbe.httpGet.port | int | `8080` |  |
| runtimes.sparkArena.tf5.startupProbe.initialDelaySeconds | int | `300` |  |
| runtimes.sparkArena.tf5.startupProbe.periodSeconds | int | `30` |  |
| runtimes.sparkArena.tf5.startupProbe.failureThreshold | int | `360` |  |
| runtimes.sparkArena.tf5.shmSize | string | `"16Gi"` |  |
