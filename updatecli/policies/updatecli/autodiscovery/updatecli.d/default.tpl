name: "deps(updatecli/policies): bump all policies"
pipelineid: {{ .pipelineid }}

autodiscovery:
  groupby: {{ .groupby }}
#{{ if .scm.enabled }}
  scmid: default
  actionid: default
# {{ end }}

  crawlers:
    updatecli:
{{ .spec | toYaml | indent 6 }}
