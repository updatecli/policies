# README 

## Description

Releasepost is a release note town crier.
It retrieves release notes from a third location, like a GitHub release,
and then copy them locally to your directory of choice.
This policy takes care of publishing any new file generated to a git repository.
It creates one file per release note version and an index file.
It can creates files using different formats like markdown, asciidoctor, or json.

## Settings

Default values are specified in the file `values.yaml`

## Example

<details><summary>Without SCM configured</summary>

```
$ updatecli manifest show ghcr.io/updatecli/policies/releasepost/releasepost:0.1.0

+++++++++++
+ PREPARE +
+++++++++++

Loading Pipeline "/tmp/updatecli/store/6a8e68ae473a5dafa270650cd74fd296e61abaf4820daf4b50e0e21c8649b710/updatecli.d/default.tpl"

SCM repository retrieved: 0


++++++++++++++++++
+ AUTO DISCOVERY +
++++++++++++++++++



++++++++++++++++++++++++++++++++++
+ DOCS: SYNCHRONIZE RELEASE NOTE +
++++++++++++++++++++++++++++++++++

name: 'docs: synchronize release note'
pipelineid: releasepost
targets:
    default:
        name: synchronize release notes
        kind: shell
        spec:
            changedif:
                kind: exitcode
                spec:
                    failure: 2
                    success: 1
                    warning: 0
            command: releasepost --dry-run="$DRY_RUN" --config .releasepost.yaml
            environments:
                - name: GITHUB_TOKEN
                - name: RELEASEPOST_GITHUB_TOKEN
                - name: PATH
version: 0.77.0
```

</details>

<details><summary>With SCM configured</summary>

```bash
$ updatecli manifest show --values testdata/values.yaml ghcr.io/updatecli/policies/releasepost/releasepost:0.1.0


+++++++++++
+ PREPARE +
+++++++++++

Loading Pipeline "/tmp/updatecli/store/6a8e68ae473a5dafa270650cd74fd296e61abaf4820daf4b50e0e21c8649b710/updatecli.d/default.tpl"

SCM repository retrieved: 1


++++++++++++++++++
+ AUTO DISCOVERY +
++++++++++++++++++



++++++++++++++++++++++++++++++++++
+ DOCS: SYNCHRONIZE RELEASE NOTE +
++++++++++++++++++++++++++++++++++

name: 'docs: synchronize release note'
pipelineid: releasepost
actions:
    default:
        kind: github/pullrequest
        spec:
            automerge: false
labels:
  - dependencies
            labels:
                - documentation
        scmid: default
scms:
    default:
        kind: github
        spec:
            branch: main
            email: updatecli-bot@updatecli.io
            owner: updatecli
            repository: releasepost
            token: ghp_xxxx
            user: updatecli-bot
            username: updatecli-bot
        disabled: false
targets:
    default:
        name: synchronize release notes
        kind: shell
        spec:
            changedif:
                kind: exitcode
                spec:
                    failure: 2
                    success: 1
                    warning: 0
            command: releasepost --dry-run="$DRY_RUN" --config config.example.yaml
            environments:
                - name: GITHUB_TOKEN
                - name: RELEASEPOST_GITHUB_TOKEN
                - name: PATH
        scmid: default
version: 0.77.0
```

</details>
