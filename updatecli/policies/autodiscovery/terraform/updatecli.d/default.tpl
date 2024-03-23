---
# Helpers
# {{ $GitHubUser := env ""}}
# {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
# {{ $GitHubPAT := env "GITHUB_TOKEN"}}
# {{ $GitHubUsername := env "GITHUB_ACTOR"}}

name: "deps(terraform): bump all dependencies"
pipelineid: {{ .pipelineid }}

autodiscovery:
  groupby: {{ .groupby }}
#{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
  scmid: default
  actionid: default
# {{ end }}

  crawlers:
    terraform:
{{ .spec | toYaml | indent 6 }}

{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
scms:
  default:
    kind: "github"
    spec:
      # Priority set to the environment variable
      user: '{{ default $GitHubUser .scm.user }}'
      email: '{{ .scm.email }}'
      owner: '{{ default $GitHubRepositoryList._0 .scm.owner }}'
      repository: '{{ default $GitHubRepositoryList._1 .scm.repository }}'
      token: '{{ default $GitHubPAT .scm.token }}'
      username: '{{ default $GitHubUsername .scm.username }}'
      branch: '{{ .scm.branch }}'

actions:
  default:
    kind: "github/pullrequest"
    scmid: "default"
    spec:
      automerge: {{ .automerge }}
      labels:
         - dependencies
{{ end }}

