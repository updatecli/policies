---
# Helpers
# {{ $GitHubUser := env ""}}
# {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
# {{ $GitHubPAT := env "GITHUB_TOKEN"}}
# {{ $GitHubUsername := env "GITHUB_ACTOR"}}

name: '{{ .name }}'
pipelineid: '{{ .pipelineid }}'

sources:
    golang:
        name: Get latest Golang version
        kind: golang

targets:
    go.mod:
        name: 'deps(gomod): Bump Golang version to {{ source "golang" }}'
        kind: golang/gomod
#{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
        scmid: default
# {{ end }}
        sourceid: golang

    github-action:
        name: 'deps(github-action): Bump Golang version to {{ source "golang" }}'
        kind: yaml
        spec:
            engine: yamlpath    
            files:
              - '.github/workflows/*'
            key: '$.jobs.build.steps[?(@.uses =~ /^actions\/setup-go/)].with.go-version'
            searchpattern: true
#{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
        scmid: default
# {{ end }}
        sourceid: golang

{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
scms:
  default:
    kind: "github"
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
    title: 'deps: Bump Golang version to {{ source "golang" }}'
    kind: "github/pullrequest"
    spec:
      automerge: {{ .automerge }}
      labels:
         - dependencies
    scmid: "default"
{{ end }}

