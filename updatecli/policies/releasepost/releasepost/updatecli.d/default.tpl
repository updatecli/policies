---
# Helpers
# {{ $GitHubUser := env ""}}
# {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
# {{ $GitHubPAT := env "GITHUB_TOKEN"}}
# {{ $GitHubUsername := env "GITHUB_ACTOR"}}

name: "docs: synchronize release note"
pipelineid: {{ .pipelineid }}

targets:
  default:
    name: synchronize release notes
    kind: shell
##{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
## {{ end }}
    spec:
      command: 'releasepost --dry-run="$DRY_RUN" --config {{ .configpath }}'
      environments:
        - name: GITHUB_TOKEN
        - name: RELEASEPOST_GITHUB_TOKEN
        - name: PATH
      changedif:
        kind: exitcode
        spec:
          warning: 0
          success: 1
          failure: 2

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
#{{ if .scm.commitusingapi }}
      commitusingapi: {{ .scm.commitusingapi }}
# {{ end }}

actions:
  default:
    kind: "github/pullrequest"
    scmid: "default"
    spec:
      automerge: {{ .automerge }}
      labels:
         - documentation
{{ end }}

