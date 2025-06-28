---
# Helpers
# {{ $GitHubUser := env ""}}
# {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
# {{ $GitHubPAT := env "GITHUB_TOKEN"}}
# {{ $GitHubUsername := env "GITHUB_ACTOR"}}

name: '{{ .name }}'
pipelineid: '{{ .pipelineid }}'

autodiscovery:
  groupby: {{ .groupby }}
#{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
  scmid: default
  actionid: default
# {{ end }}

  crawlers:
    golang/gomod:
{{ .spec | toYaml | indent 6 }}

{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
scms:
  default:
    kind: {{ default "github" .scm.kind }}
    spec:
      # Priority set to the environment variable
      user: '{{ default $GitHubUser .scm.user}}'
# {{ if .scm.email }}
      email: '{{ .scm.email }}'
# {{ end }}
      owner: '{{ default $GitHubRepositoryList._0 .scm.owner }}'
      repository: '{{ default $GitHubRepositoryList._1 .scm.repository}}'
      token: '{{ default $GitHubPAT .scm.token }}'
      username: '{{ default $GitHubUsername .scm.username }}'
      branch: '{{ .scm.branch }}'
#{{ if .scm.commitusingapi }}
      commitusingapi: {{ .scm.commitusingapi }}
# {{ end }}

actions:
  default:
    kind: {{ default "github/pullrequest" .action.kind }}
    scmid: "default"
    spec:
# {{ if .automerge }}
      automerge: {{ .automerge }}
# {{ end }}
# {{ if .labels }}
      labels:
# {{ range .labels }}
        - {{ . }}
# {{ end }}
# {{ end }}
{{ end }}

