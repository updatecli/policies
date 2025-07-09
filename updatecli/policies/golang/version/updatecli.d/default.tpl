name: '{{ .name }}'
pipelineid: '{{ .pipelineid }}'
version: v0.103.0

sources:
    golang:
        name: Get latest Golang version
        kind: golang

targets:
    go.mod:
        name: 'deps(gomod): Bump Golang version to {{ source "golang" }}'
        kind: golang/gomod
#{{ if .scm.enabled }}
        scmid: default
        actionid: default
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
#{{ if .scm.enabled }}
        scmid: default
# {{ end }}
        sourceid: golang