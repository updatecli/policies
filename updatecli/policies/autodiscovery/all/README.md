# All Autodiscovery Policy

This policy wraps Updatecli autodiscovery for projects using multiple ecosystems simultaneously.
It enables all supported autodiscovery crawlers in a single pipeline, detects available updates across technologies, and can optionally open pull requests through a supported SCM provider.

## Overview

This policy builds an Updatecli pipeline that activates the following autodiscovery crawlers in parallel:

- `cargo`
- `dockerfile`
- `dockercompose`
- `helmfile`
- `helm`
- `golang/gomod`
- `maven`
- `npm`
- `rancher/fleet`
- `terraform`

The generated pipeline can:

- detect dependency updates across all supported ecosystems at once
- group discovered updates according to your `groupby` setting
- apply changes locally, or create pull requests when SCM is enabled

Each crawler can be individually enabled or disabled and configured using its own `spec` block under `crawlers`.

## Requirements

- `updatecli` CLI installed
- access to an OCI registry if you want to publish or consume the bundle from a registry
- optional: `docker` or another OCI client for registry authentication
- SCM credentials when `scm.enabled: true`

## Supported SCM Backends

When SCM support is enabled, this policy can create pull requests or merge requests using:

- `github`

The default `scm.env_token` value is `GITHUB_TOKEN`.
The `GITHUB_REPOSITORY` environment variable is used automatically to resolve `owner` and `repository` when running inside a GitHub Actions workflow.

## Policy Configuration

### Available Input Values

The default `values.yaml` exposes these top-level inputs:

- `autodiscovery.groupby`: autodiscovery grouping strategy
- `crawlers`: map of crawler names to enable/disable flags and optional `spec` blocks
- `action.enabled`: controls whether a GitHub pull request action is injected
- `action.spec`: raw GitHub pull request action configuration (including `labels`)
- `scm.enabled`: enables SCM integration
- `scm.user`, `scm.owner`, `scm.repository`, `scm.branch`, `scm.token`, `scm.username`: SCM connection settings
- `scm.email`, `scm.commitusingapi`: optional SCM settings

### Example Values

The following example enables all crawlers and opens one pull request per ecosystem grouping:

```yaml
autodiscovery:
  groupby: all

crawlers:
  cargo:
    enabled: true
  dockerfile:
    enabled: true
  dockercompose:
    enabled: true
  helmfile:
    enabled: true
  helm:
    enabled: true
  golang:
    gomod:
      enabled: true
  maven:
    enabled: true
  npm:
    enabled: true
  rancher:
    fleet:
      enabled: true
  terraform:
    enabled: true

action:
  enabled: true
  spec:
    labels:
      - dependencies

scm:
  enabled: true
  user: updatecli-bot
  email: updatecli-bot@example.com
  owner: myorg
  repository: myrepo
  username: updatecli-bot
  branch: main
```

To disable a specific crawler, set its `enabled` flag to `false`:

```yaml
crawlers:
  maven:
    enabled: false
```

## How It Works

This policy renders a manifest that activates multiple crawlers simultaneously:

```yaml
autodiscovery:
  groupby: <groupby>
  scmid: default
  actionid: default
  crawlers:
    cargo: ...
    dockerfile: ...
    dockercompose: ...
    helmfile: ...
    helm: ...
    golang/gomod: ...
    maven: ...
    npm: ...
    rancher/fleet: ...
    terraform: ...
```

If `scm.enabled` is `false` (or `GITHUB_REPOSITORY` is not set), the pipeline applies changes locally without opening pull requests.

If `scm.enabled` is `true` (or `GITHUB_REPOSITORY` is set), the policy injects a default GitHub SCM and pull request action.

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
updatecli manifest show --values values.yaml ghcr.io/updatecli/policies/autodiscovery/all:0.7.0
```

```sh
updatecli pipeline diff --values values.yaml ghcr.io/updatecli/policies/autodiscovery/all:0.7.0
```

```sh
updatecli pipeline apply --values values.yaml ghcr.io/updatecli/policies/autodiscovery/all:0.7.0
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
  --tag "$OCI_REGISTRY/autodiscovery/all" \
  .
```

After publishing, reference the bundle by tag:

```sh
updatecli manifest show "$OCI_REGISTRY/autodiscovery/all:0.7.0"
```

## Troubleshooting

### No updates detected

1. Show the rendered manifest and verify that the crawlers are present:

   ```sh
   updatecli manifest show --config updatecli.d --values values.yaml
   ```

2. Confirm that at least one crawler is enabled in your `crawlers` configuration.

3. Run in debug mode:

   ```sh
   updatecli pipeline diff --log-level debug --config updatecli.d --values values.yaml
   ```

### Pull requests are not created

1. Confirm `scm.enabled: true` (or that `GITHUB_REPOSITORY` is set) and that `action.enabled: true`.

2. Verify that `GITHUB_TOKEN` is exported.

3. Confirm repository targeting values such as `owner`, `repository`, and `branch`.

## Related Documentation

- Updatecli docs: <https://www.updatecli.io>
- Autodiscovery docs: <https://www.updatecli.io/docs/core/autodiscovery/>
- Compose docs: <https://www.updatecli.io/docs/core/compose/>
- Sharing and reuse: <https://www.updatecli.io/docs/core/shareandreuse/>
- Updatecli policies repository: <https://github.com/updatecli/policies>
