name: '{{ .name }}'
# {{ if .pipelineid }}
pipelineid: '{{ .pipelineid }}'
# {{ end }}

autodiscovery:
  groupby: {{ .groupby }}
  # {{ if .scm.enabled }}
  scmid: default
  actionid: default
  # {{ end }}

  crawlers:
    helm:
{{ .spec | toYaml | indent 6 }}