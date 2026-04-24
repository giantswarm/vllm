{{/*
Resolve the image reference for the bwi-kserve-vllm runtime.
Falls back to .Chart.AppVersion when .Values.image.tag is empty so chart and
image stay in lockstep without operator action.
*/}}
{{- define "vllm.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository $tag -}}
{{- end -}}

{{/*
Resolve the image reference for a sparkArena variant.
Variant values are passed in via `dict "Values" .Values "Variant" $variant`.
The variant supplies its own tag (date-rev mirror tag); registry/repository
share the top-level image config because the mirror lives in the same gsoci
repo as the bwi-kserve-vllm image.
*/}}
{{- define "vllm.sparkArenaImage" -}}
{{- $tag := .Variant.tag | default .Values.image.tag | default .Chart.AppVersion -}}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository $tag -}}
{{- end -}}

{{/*
Common labels emitted on every ClusterServingRuntime. The `app.kubernetes.io/part-of`
label is the BWI marker the bwi-clusterservingruntime ValidatingWebhookConfiguration
selects on; the chart label keeps Helm release diagnostics readable.
*/}}
{{- define "vllm.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: {{ .Values.partOfLabel }}
{{- with (index .Chart.Annotations "application.giantswarm.io/team") }}
application.giantswarm.io/team: {{ . | quote }}
{{- end }}
{{- end -}}
