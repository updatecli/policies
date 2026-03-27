# Golang Version Policy

Automatically update the Golang version in `go.mod` and GitHub Actions workflow files to the latest stable release.

## Overview

This policy runs a single Updatecli pipeline that:

- fetches the latest Golang version using the Updatecli `golang` source kind
- updates the Go version directive in `go.mod` using the `golang/gomod` target kind
- updates the `go-version` field for `actions/setup-go` steps in `.github/workflows/*` files

The two targets updated are:

1. `go.mod` — the Go toolchain version directive
2. GitHub Action workflows — the `go-version` input for `actions/setup-go` steps at path `$.jobs.build.steps[?(@.uses =~ /^actions\/setup-go/)].with.go-version`

## Requirements

- `updatecli` CLI installed
- access to an OCI registry if you want to publish or consume the bundle from a registry
- optional: `docker` or another OCI client for registry authentication
- SCM credentials when `scm.enabled: true`

## Supported SCM Backends

When SCM support is enabled, this policy can create pull requests or merge requests using:

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

- `name`: pipeline name (default: `deps: Bump Golang version`)
- `pipelineid`: optional pipeline identifier
- `automerge`: controls GitHub and GitHub search pull request automerge behavior
- `labels`: labels applied on GitHub and GitHub search pull requests
- `scm`: optional SCM configuration used to open pull requests

### Example Values

The following example updates Golang and opens a pull request:

```yaml
name: "deps: Bump Golang version"
pipelineid: "golang/version"
automerge: false

labels:
  - dependencies

scm:
  enabled: true
  kind: github
  env_token: GITHUB_TOKEN
  user: updatecli-bot
  email: updatecli-bot@example.com
  owner: myorg
  repository: myrepo
  username: updatecli-bot
  branch: main
```

To target multiple GitHub repositories discovered by search instead of a single repository, switch the SCM kind to `githubsearch`:

```yaml
scm:
  enabled: true
  kind: githubsearch
  env_token: GITHUB_TOKEN
  search: |
    org:myorg
    archived:false
    fork:false
  branch: main
  username: updatecli-bot
  email: updatecli-bot@example.com
  limit: 3
```

## How It Works

This policy renders a manifest with the following structure:

```yaml
name: <name>
pipelineid: <pipelineid>

sources:
  golang:
    kind: golang

targets:
  gomod:
    kind: golang/gomod
    spec:
      file: go.mod

  githubaction:
    kind: yaml
    spec:
      engine: yamlpath
      key: $.jobs.build.steps[?(@.uses =~ /^actions\/setup-go/)].with.go-version
      files:
        - .github/workflows/*
      searchpattern: true
```

The `golang` source kind retrieves the latest stable Golang version without requiring any GitHub API credentials. If `scm.enabled` is `true`, the policy injects a `default` SCM and action to open pull requests.

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

Apply the policy locally or through the configured SCM action:

```sh
updatecli pipeline apply --config updatecli.d --values values.yaml
```

### Using from an OCI Registry

Consume the published bundle directly from a registry:

```sh
updatecli manifest show --values values.yaml ghcr.io/updatecli/policies/golang/version:0.7.0
```

```sh
updatecli pipeline diff --values values.yaml ghcr.io/updatecli/policies/golang/version:0.7.0
```

```sh
updatecli pipeline apply --values values.yaml ghcr.io/updatecli/policies/golang/version:0.7.0
```

## Authentication

Authenticate to your OCI registry before pushing or pulling bundles:

```sh
docker login "$OCI_REGISTRY"
```

When using SCM integration, export the token referenced by `scm.env_token` before running Updatecli.

## Publish

Publish this policy bundle to an OCI registry. The `version` field in `Policy.yaml` defines the bundle tag:

```sh
updatecli manifest push \
  --config updatecli.d \
  --values values.yaml \
  --policy Policy.yaml \
  --tag "$OCI_REGISTRY/golang/version" \
  .
```

After publishing, reference the bundle by tag:

```sh
updatecli manifest show "$OCI_REGISTRY/golang/version:0.7.0"
```

## Troubleshooting

### No updates detected

1. Show the rendered manifest and verify the source and target configuration:

   ```sh
   updatecli manifest show --config updatecli.d --values values.yaml
   ```

2. Confirm that `go.mod` exists at the root of the repository and contains a `go` version directive.

3. Confirm that at least one workflow file contains an `actions/setup-go` step with a `go-version` input.

4. Run in debug mode:

   ```sh
   updatecli pipeline diff --log-level debug --config updatecli.d --values values.yaml
   ```

### Pull requests are not created

1. Confirm `scm.enabled: true` and that the correct `scm.kind` is configured.

2. Verify that the token environment variable referenced by `scm.env_token` is exported.

3. Confirm repository targeting values such as `owner`, `repository`, `branch`, or `search`.

4. For GitHub and GitHub search, remember that `labels` and `automerge` are applied only when the policy creates GitHub pull requests.

## Related Documentation

- Updatecli docs: <https://www.updatecli.io>
- Golang source plugin docs: <https://www.updatecli.io/docs/plugins/sources/golang/>
- Golang/gomod target plugin docs: <https://www.updatecli.io/docs/plugins/targets/golang/gomod/>
- Compose docs: <https://www.updatecli.io/docs/core/compose/>
- Sharing and reuse: <https://www.updatecli.io/docs/core/shareandreuse/>
- Updatecli policies repository: <https://github.com/updatecli/policies>
