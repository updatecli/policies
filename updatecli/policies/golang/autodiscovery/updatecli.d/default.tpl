# Helpers
# {{ $GitHubUser := env ""}}
# {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
# {{ $GitHubPAT := env "GITHUB_TOKEN"}}
# {{ $GitHubUsername := env "GITHUB_ACTOR"}}

name: '{{ .name }}'
pipelineid: '{{ .pipelineid }}'

autodiscovery:
  groupby: {{ .groupby }}
#{{ if .scm.enabled }}
  scmid: default
  actionid: default
# {{ end }}

  crawlers:
    golang/gomod:
{{ .spec | toYaml | indent 6 }}

