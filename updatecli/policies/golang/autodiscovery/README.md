# Golang Autodiscovery Policy

Automatically discover and update Golang version and Go module dependencies across repositories by scanning `go.mod` files.

## Overview

This policy builds an Updatecli pipeline with one autodiscovery crawler:

- `golang/gomod`

The generated pipeline can:

- detect Golang version updates
- detect Go module dependency updates from `go.mod`
- group discovered updates according to your `groupby` setting
- apply changes locally, or create pull requests when SCM is enabled

The policy does not hardcode dependency rules. Instead, it passes your `spec` values directly to the Golang autodiscovery crawler so you can tune behavior with the same options supported by the Updatecli Golang autodiscovery plugin.

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

- `name`: pipeline name
- `pipelineid`: optional pipeline identifier
- `automerge`: controls GitHub and GitHub search pull request automerge behavior
- `labels`: labels applied on GitHub and GitHub search pull requests
- `groupby`: autodiscovery grouping strategy
- `scm`: optional SCM configuration used to open pull requests
- `spec`: raw Golang autodiscovery crawler configuration
- `pipeline.labels`: additional labels applied to the generated pipeline metadata

### Example Values

The following example updates Go dependencies with patch releases only and opens one pull request per detected update:

```yaml
name: "deps(golang): bump patch dependencies"
pipelineid: "golang/autodiscovery/patch"
groupby: individual
automerge: false

labels:
  - dependencies
  - golang

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

spec:
  versionfilter:
    kind: semver
    pattern: patch
  ignore:
    - modules:
        github.com/stretchr/testify: ""
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

This policy renders a manifest equivalent to the following structure:

```yaml
name: <name>
pipelineid: <pipelineid>

autodiscovery:
  groupby: <groupby>
  scmid: default
  actionid: default
  crawlers:
    golang/gomod:
      <spec>
```

If `scm.enabled` is `false`, the pipeline runs without any SCM or pull request action and applies changes locally.

If `scm.enabled` is `true`, the policy also injects a `default` SCM and `default` action matching the selected SCM provider.

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
updatecli manifest show --values values.yaml ghcr.io/updatecli/policies/golang/autodiscovery:0.12.0
```

```sh
updatecli pipeline diff --values values.yaml ghcr.io/updatecli/policies/golang/autodiscovery:0.12.0
```

```sh
updatecli pipeline apply --values values.yaml ghcr.io/updatecli/policies/golang/autodiscovery:0.12.0
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
  --tag "$OCI_REGISTRY/golang/autodiscovery" \
  .
```

After publishing, reference the bundle by tag:

```sh
updatecli manifest show "$OCI_REGISTRY/golang/autodiscovery:0.12.0"
```

## Troubleshooting

### No updates detected

1. Show the rendered manifest and verify that the `golang/gomod` crawler is present:

   ```sh
   updatecli manifest show --config updatecli.d --values values.yaml
   ```

2. Check your `spec` filters. Rules such as `versionfilter`, `ignore`, or `only` can legitimately reduce the result set to zero.

3. Run in debug mode:

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
- Autodiscovery docs: <https://www.updatecli.io/docs/core/autodiscovery/>
- Compose docs: <https://www.updatecli.io/docs/core/compose/>
- Sharing and reuse: <https://www.updatecli.io/docs/core/shareandreuse/>
- Golang autodiscovery plugin docs: <https://www.updatecli.io/docs/plugins/autodiscovery/golang/>
- Updatecli policies repository: <https://github.com/updatecli/policies>