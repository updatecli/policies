name: '{{ .name }}'
pipelineid: '{{ .pipelineid }}'
version: v0.109.0

autodiscovery:
  groupby: {{ .groupby }}
#{{ if .scm.enabled }}
  scmid: default
  actionid: default
# {{ end }}

  crawlers:
    golang/gomod:
{{ .spec | toYaml | indent 6 }}

