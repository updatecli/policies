# golangci-lint GitHub Action Policy

Automatically update the `golangci/golangci-lint-action` step version in GitHub Actions workflow files to the latest golangci-lint release.

## Overview

This policy runs a single Updatecli pipeline that:

- fetches the latest `golangci/golangci-lint` release from GitHub releases
- updates the `with.version` field in all `.github/workflows/*.yaml` files for steps using `golangci/golangci-lint-action`

The YAML path targeted is:

```
$.jobs.*.steps[?(@.uses =~ /^golangci\/golangci-lint-action/)].with.version
```

## Requirements

- `updatecli` CLI installed
- a GitHub token with read access to fetch release information
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

- `name`: pipeline name (defaults to `deps: Updatecli version used by GitHub action`)
- `pipelineid`: optional pipeline identifier
- `automerge`: controls GitHub and GitHub search pull request automerge behavior
- `labels`: labels applied on GitHub and GitHub search pull requests
- `scm`: optional SCM configuration used to open pull requests
- `versionpattern`: semver pattern used to filter releases (default: `*`)
- `github.env_token`: environment variable name holding the GitHub token (default: `GITHUB_TOKEN`)
- `github.env_username`: environment variable name holding the GitHub username (default: `GITHUB_ACTOR`)

### Example Values

The following example updates golangci-lint in GitHub Action workflows and opens a pull request:

```yaml
pipelineid: "golangci-lint"
automerge: false

labels:
  - chore
  - dependencies

versionpattern: "*"

github:
  env_token: GITHUB_TOKEN
  env_username: GITHUB_ACTOR

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
name: deps: Updatecli version used by GitHub action
pipelineid: <pipelineid>

sources:
  golangci-lint:
    kind: githubrelease
    spec:
      owner: golangci
      repository: golangci-lint
      versionfilter:
        kind: semver
        pattern: <versionpattern>

targets:
  githubaction:
    kind: yaml
    spec:
      engine: yamlpath
      key: $.jobs.*.steps[?(@.uses =~ /^golangci\/golangci-lint-action/)].with.version
      files:
        - .github/workflows/*
      searchpattern: true
```

The `github` block provides credentials for the `githubrelease` source plugin. If `scm.enabled` is `true`, the policy injects a `default` SCM and action to open pull requests.

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
updatecli manifest show --values values.yaml ghcr.io/updatecli/policies/golangci-lint/githubaction:0.8.0
```

```sh
updatecli pipeline diff --values values.yaml ghcr.io/updatecli/policies/golangci-lint/githubaction:0.8.0
```

```sh
updatecli pipeline apply --values values.yaml ghcr.io/updatecli/policies/golangci-lint/githubaction:0.8.0
```

## Authentication

Authenticate to your OCI registry before pushing or pulling bundles:

```sh
docker login "$OCI_REGISTRY"
```

Export the GitHub token before running Updatecli:

```sh
export GITHUB_TOKEN="ghp_xxxx"
export GITHUB_ACTOR="myusername"
```

When using SCM integration, also export the token referenced by `scm.env_token`.

## Publish

Publish this policy bundle to an OCI registry. The `version` field in `Policy.yaml` defines the bundle tag:

```sh
updatecli manifest push \
  --config updatecli.d \
  --values values.yaml \
  --policy Policy.yaml \
  --tag "$OCI_REGISTRY/golangci-lint/githubaction" \
  .
```

After publishing, reference the bundle by tag:

```sh
updatecli manifest show "$OCI_REGISTRY/golangci-lint/githubaction:0.8.0"
```

## Troubleshooting

### No updates detected

1. Show the rendered manifest and verify the source and target configuration:

   ```sh
   updatecli manifest show --config updatecli.d --values values.yaml
   ```

2. Confirm that your workflow files use the `golangci/golangci-lint-action` action with a `with.version` field.

3. Check that `versionpattern` is not filtering out available releases.

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
- GitHub release source plugin docs: <https://www.updatecli.io/docs/plugins/sources/githubrelease/>
- Compose docs: <https://www.updatecli.io/docs/core/compose/>
- Sharing and reuse: <https://www.updatecli.io/docs/core/shareandreuse/>
- golangci-lint-action repository: <https://github.com/golangci/golangci-lint-action>
- Updatecli policies repository: <https://github.com/updatecli/policies>
