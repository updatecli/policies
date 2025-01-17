## DESCRIPTION

This policy can be used to copy files from a source repository to a destination repository.

By default the policy uses the following environment variable to set default values

* `GITHUB_REPOSITORY`: To retrieve the GitHub repository to publish the files. It must be of type `OWNER/REPOSITORY`

* `GITHUB_ACTOR`: To retrieve the GitHub username used for authentication
* `GITHUB_TOKEN`: To retrieve the GitHub token used for authentication

Here is a basic example of a configuration

```values.yaml
scm:
  author: "Updatecli bot"
  branch: "main"
  owner: "updatecli"
  repository: "udash"
  username: "updatecli-bot"

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

export GITHUB_TOKEN=yyy
export GITHUB_ACTOR=xxx
updatecli diff --values values.yaml ghcr.io/updatecli/policies/updatecli/file:latest