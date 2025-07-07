name: '{{ .name }}'
pipelineid: '{{ .pipelineid }}'
version: v0.103.0

autodiscovery:
  groupby: {{ .groupby }}
#{{ if .scm.enabled }}
  scmid: default
# {{ end }}

  crawlers:
    golang/gomod:
{{ .spec | toYaml | indent 6 }}

