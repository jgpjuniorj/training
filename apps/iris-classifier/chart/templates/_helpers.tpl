{{- define "iris.name" -}}
iris-classifier
{{- end -}}

{{- define "iris.labels" -}}
app.kubernetes.io/name: {{ include "iris.name" . }}
app.kubernetes.io/part-of: kiale-demo
{{- end -}}
