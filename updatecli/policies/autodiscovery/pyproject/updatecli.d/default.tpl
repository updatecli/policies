name: '{{ .name }}'
version: "0.116.1"
#{{ if .pipelineid }}
pipelineid: '{{ .pipelineid }}'
#{{ end }}

autodiscovery:
  groupby: {{ .groupby }}
  #{{ if .scm.enabled }}
  scmid: default
  actionid: default
  # {{ end }}

  crawlers:
    pyproject:
{{ .spec | toYaml | indent 6 }}
