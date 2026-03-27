# File Sync Policy

Copy files from a source git repository to a destination git repository and open a pull request with the changes.

## Overview

This policy runs a single Updatecli pipeline that:

- clones a source git repository (configured under `src`)
- copies one or more files from that source to corresponding paths in the destination repository
- commits and optionally opens a pull request through the configured SCM backend

This is useful for keeping shared configuration files (linter configs, CI snippets, `.gitignore`, etc.) synchronized across multiple repositories from a single canonical source.

## Requirements

- `updatecli` CLI installed
- a list of file pairs (`src`/`dst`) to copy
- a source repository URL accessible from where Updatecli runs
- SCM credentials for the destination repository
- access to an OCI registry if you want to publish or consume the bundle from a registry
- optional: `docker` or another OCI client for registry authentication

## Supported SCM Backends

This policy always requires SCM configuration for the destination repository. It supports:

- `github`
- `githubsearch`
- `gitlab`
- `gitea`
- `bitbucket`
- `stash`

The default `scm.env_token` value is `GITHUB_TOKEN`. For non-GitHub providers, set `scm.env_token` to the environment variable that contains the correct token for that platform.

## Policy Configuration

### Available Input Values

The default `values.yaml` exposes these top-level inputs:

- `title`: optional pipeline title override
- `pipelineid`: optional pipeline identifier
- `files`: list of `{src: "", dst: ""}` pairs defining which files to copy
- `pr.automerge`: controls pull request automerge behavior (default: `false`)
- `pr.labels`: labels applied to pull requests
- `scm`: destination repository SCM configuration
  - `kind`: SCM provider (`github`, `gitea`, `bitbucket`, `gitlab`, `stash`)
  - `commitusingapi`: commit via the provider API rather than git (default: `true`, GitHub only)
  - `user`: git commit author name
  - `email`: git commit author email
  - `env_token`: environment variable holding the SCM token (default: `GITHUB_TOKEN`)
  - `owner`: repository owner or organization
  - `repository`: repository name
  - `branch`: target branch
  - `username`: SCM username for authentication
  - `commitmessage`: structured commit message (`type`, `title`, `body`, `scope`, etc.)
- `src`: source repository
  - `url`: git clone URL of the source repository
  - `branch`: branch to read files from

### Example Values

The following example syncs shared config files from the `updatecli/updatecli` repository into the destination repository:

```yaml
pipelineid: "file-sync"

files:
  - src: .golangci.yml
    dst: .golangci.yml
  - src: _typos.toml
    dst: _typos.toml
  - src: codecov.yaml
    dst: codecov.yaml

src:
  url: "https://github.com/updatecli/updatecli.git"
  branch: "main"

pr:
  automerge: false
  labels:
    - dependencies
    - chore

scm:
  kind: github
  commitusingapi: true
  user: updatecli-bot
  email: updatecli-bot@example.com
  env_token: GITHUB_TOKEN
  owner: myorg
  repository: myrepo
  branch: main
  username: updatecli-bot
  commitmessage:
    type: chore
```

To target a destination managed by GitLab instead of GitHub:

```yaml
scm:
  kind: gitlab
  env_token: GITLAB_TOKEN
  user: updatecli-bot
  email: updatecli-bot@example.com
  owner: mygroup
  repository: myrepo
  branch: main
  username: updatecli-bot
```

## How It Works

This policy renders a manifest with the following structure:

```yaml
pipelineid: <pipelineid>

scms:
  src:
    kind: git
    spec:
      url: <src.url>
      branch: <src.branch>
  default:
    kind: <scm.kind>
    spec:
      owner: <scm.owner>
      repository: <scm.repository>
      branch: <scm.branch>
      ...

sources:
  <file-id>:
    scmid: src
    kind: file
    spec:
      file: <src>

targets:
  <file-id>:
    scmid: default
    kind: file
    spec:
      file: <dst>
```

The `src` SCM is used only for reading; the `default` SCM is used for writing and opening pull requests. Unlike most other policies, there is no `scm.enabled` toggle — SCM is always active.

## Quick Usage

### Local Testing

Show the rendered manifest:

```sh
updatecli manifest show --config updatecli.d --values values.yaml
```

Run a dry-run:

```sh
updatecli pipeline diff --config updatecli.d --values values.yaml
```

Apply the policy and commit files through the configured SCM action:

```sh
updatecli pipeline apply --config updatecli.d --values values.yaml
```

### Using from an OCI Registry

Consume the published bundle directly from a registry:

```sh
updatecli manifest show --values values.yaml ghcr.io/updatecli/policies/file:0.3.3
```

```sh
updatecli pipeline diff --values values.yaml ghcr.io/updatecli/policies/file:0.3.3
```

```sh
updatecli pipeline apply --values values.yaml ghcr.io/updatecli/policies/file:0.3.3
```

## Authentication

Authenticate to your OCI registry before pushing or pulling bundles:

```sh
docker login "$OCI_REGISTRY"
```

Export the SCM token before running Updatecli:

```sh
export GITHUB_TOKEN="ghp_xxxx"
```

## Publish

Publish this policy bundle to an OCI registry. The `version` field in `Policy.yaml` defines the bundle tag:

```sh
updatecli manifest push \
  --config updatecli.d \
  --values values.yaml \
  --policy Policy.yaml \
  --tag "$OCI_REGISTRY/file" \
  .
```

After publishing, reference the bundle by tag:

```sh
updatecli manifest show "$OCI_REGISTRY/file:0.3.3"
```

## Troubleshooting

### No updates detected

1. Show the rendered manifest and verify the source and target file paths:

   ```sh
   updatecli manifest show --config updatecli.d --values values.yaml
   ```

2. Confirm that the `src.url` is accessible from your environment and that the files exist on the `src.branch`.

3. Run in debug mode:

   ```sh
   updatecli pipeline diff --log-level debug --config updatecli.d --values values.yaml
   ```

### Pull requests are not created

1. Verify that the token environment variable referenced by `scm.env_token` is exported and has write access to the destination repository.

2. Confirm that `scm.owner`, `scm.repository`, and `scm.branch` are set correctly.

3. Check that `scm.kind` matches your destination SCM provider.

## Related Documentation

- Updatecli docs: <https://www.updatecli.io>
- File target plugin docs: <https://www.updatecli.io/docs/plugins/targets/file/>
- Compose docs: <https://www.updatecli.io/docs/core/compose/>
- Sharing and reuse: <https://www.updatecli.io/docs/core/shareandreuse/>
- Updatecli policies repository: <https://github.com/updatecli/policies>
