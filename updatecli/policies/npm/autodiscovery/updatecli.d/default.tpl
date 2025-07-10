name: "deps: bump NPM packages version"
pipelineid: {{ .pipelineid }}
version: v0.103.0

autodiscovery:
  groupby: {{ .groupby }}
#{{ if .scm.enabled }}
  scmid: default
  actionid: default
# {{ end }}

  crawlers:
    npm:
{{ .spec | toYaml | indent 6 }}