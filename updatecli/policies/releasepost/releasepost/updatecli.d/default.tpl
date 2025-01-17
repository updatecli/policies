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
      command: 'releasepost --detailed-exit-code --dry-run="$DRY_RUN" --config {{ .configpath }}'
      environments:
        - name: GITHUB_TOKEN
        - name: RELEASEPOST_GITHUB_TOKEN
        - name: PATH
      changedif:
        kind: exitcode
        spec:
          success: 0
          warning: 2
          failure: 1

{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
scms:
  default:
    kind: "github"
    spec:
      # Priority set to the environment variable
      user: '{{ default $GitHubUser .scm.user }}'
# {{ if .scm.email }}
      email: '{{ .scm.email }}'
# {{ end }}
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
# {{ if .labels }}
      labels:
# {{ range .labels }}
         - {{ . }}
# {{ end }}
# {{ end }}
{{ end }}

