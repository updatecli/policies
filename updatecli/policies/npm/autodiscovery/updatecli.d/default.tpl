---
# Helpers
# {{ $GitHubUser := env ""}}
# {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
# {{ $GitHubPAT := env "GITHUB_TOKEN"}}
# {{ $GitHubUsername := env "GITHUB_ACTOR"}}}

name: "Updatecli Autodiscovery"
pipelineid: {{ .pipelineid }}

autodiscovery:
  groupby: {{ .autodiscovery.groupby }}
#{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
  scmid: default
  actionid: default
# {{ end }}

  crawlers:
    npm:
{{ .npm.spec | toYaml | indent 6 }}

{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
scms:
  default:
    kind: "github"
    spec:
      # Priority set to the environment variable
      user: '{{ default .scm.user $GitHubUser}}'
      email: '{{ .scm.email }}'
      owner: '{{ default .scm.owner $GitHubRepositoryList._0 }}'
      repository: '{{ default .scm.repository $GitHubRepositoryList._1 }}'
      token: '{{ default .scm.token $GitHubPAT }}'
      username: '{{ default .scm.username $GitHubUsername }}'
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

