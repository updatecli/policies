---
name: '{{ .name }}'

#{{ if .pipelineid }}
pipelineid: '{{ .pipelineid }}'
#{{ end }}

autodiscovery:
  groupby: {{ .autodiscovery.groupby }}
{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
  scmid: default
{{ end }}
{{ if or (.action.enabled) (env "GITHUB_REPOSITORY") }}
  actionid: default
{{ end }}

  crawlers:
    cargo:
{{ .crawlers.cargo.spec | toYaml | indent 6 }}
    dockerfile:
{{ .crawlers.dockerfile.spec | toYaml | indent 6 }}
    dockercompose:
{{ .crawlers.dockercompose.spec | toYaml | indent 6 }}
    helmfile:
{{ .crawlers.helmfile.spec | toYaml | indent 6 }}
    helm:
{{ .crawlers.helm.spec | toYaml | indent 6 }}
    golang/gomod:
{{ .crawlers.golang.gomod.spec | toYaml | indent 6 }}
    maven:
{{ .crawlers.maven.spec | toYaml | indent 6 }}
    npm:
{{ .crawlers.npm.spec | toYaml | indent 6 }}
    rancher/fleet:
{{ .crawlers.rancher.fleet.spec | toYaml | indent 6 }}
    terraform:
{{ .crawlers.terraform.spec | toYaml | indent 6 }}

scms:
{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
  default:
    kind: "github"
    spec:
      # {{ $GitHubUser := env ""}}
      # Priority set to the environment variable
      user: '{{ default $GitHubUser .scm.user }}'
      email: '{{ .scm.email }}'
      # {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
      owner: '{{ default $GitHubRepositoryList._0 .scm.owner }}'
      repository: '{{ default $GitHubRepositoryList._1 .scm.repository }}'
      # {{ $GitHubPAT := env "GITHUB_TOKEN"}}
      token: '{{ default $GitHubPAT .scm.token }}'
      # {{ $GitHubUsername := env "GITHUB_ACTOR"}}}
      username: '{{ default $GitHubUsername .scm.username }}'
      branch: '{{ .scm.branch }}'
#{{ if .scm.commitusingapi }}
      commitusingapi: {{ .scm.commitusingapi }}
# {{ end }}
{{ end }}

{{ if or (.action.enabled) (env "GITHUB_REPOSITORY") }}
actions:
  default:
    kind: "github/pullrequest"
    scmid: "default"
    spec:
{{ .action.spec | toYaml | indent 6 }}
{{ end }}
