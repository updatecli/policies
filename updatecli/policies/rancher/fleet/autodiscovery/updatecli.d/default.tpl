name: "deps: bump Rancher Fleet dependencies"
pipelineid: '{{ .pipelineid }}'
version: v0.103.0

autodiscovery:
  groupby: {{ .autodiscovery.groupby }}
#{{ if .scm.enabled }}
  scmid: default
  actionid: default
# {{ end }}

  crawlers:
    rancher/fleet:
{{ .spec | toYaml | indent 6 }}