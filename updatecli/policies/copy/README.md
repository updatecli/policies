## DESCRIPTION

This policy can be used to copy files from a source repository to a local file


Here is a basic example of a configuration

```values.yaml

src:
  url: "https://github.com/updatecli/updatecli.git"
  branch: "main"

files:
  - src: .golangci.yml
    dst: .golangci.yml
  - src: _typos.toml
    dst: _typos.toml
  - src: codecov.yaml
    dst: codecov.yaml
  - src: .gitignore
    dst: .gitignore
```

Then you can execute this policy running:

```
updatecli diff --values values.yaml ghcr.io/updatecli/policies/updatecli/copy:latest
```
