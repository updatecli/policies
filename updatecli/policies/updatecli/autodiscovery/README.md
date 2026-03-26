# Updatecli Autodiscovery Policy

Automatically discover and update Updatecli policy versions across repositories by scanning `updatecli-compose.yaml` files.

## Overview

This policy builds an Updatecli pipeline with one autodiscovery crawler:

- `updatecli`

The generated pipeline can:

- detect Updatecli policy version updates referenced in `updatecli-compose.yaml` files
- group discovered updates according to your `groupby` setting
- apply changes locally, or create pull requests when SCM is enabled

The policy does not hardcode dependency rules. Instead, it passes your `spec` values directly to the Updatecli autodiscovery crawler so you can tune behavior with the same options supported by the Updatecli autodiscovery plugin.

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

- `pipelineid`: optional pipeline identifier
- `automerge`: controls GitHub and GitHub search pull request automerge behavior
- `labels`: labels applied on GitHub and GitHub search pull requests
- `groupby`: autodiscovery grouping strategy
- `scm`: optional SCM configuration used to open pull requests
- `spec`: raw Updatecli autodiscovery crawler configuration (commented out by default)
- `pipeline.labels`: additional labels applied to the generated pipeline metadata

### Example Values

The following example keeps all policy updates grouped into a single pull request:

```yaml
pipelineid: "updatecli_policies"
groupby: all
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

This policy renders a manifest equivalent to the following structure:

```yaml
pipelineid: <pipelineid>

autodiscovery:
  groupby: <groupby>
  scmid: default
  actionid: default
  crawlers:
    updatecli:
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
updatecli manifest show --values values.yaml ghcr.io/updatecli/policies/updatecli/autodiscovery:0.8.0
```

```sh
updatecli pipeline diff --values values.yaml ghcr.io/updatecli/policies/updatecli/autodiscovery:0.8.0
```

```sh
updatecli pipeline apply --values values.yaml ghcr.io/updatecli/policies/updatecli/autodiscovery:0.8.0
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
  --tag "$OCI_REGISTRY/updatecli/autodiscovery" \
  .
```

After publishing, reference the bundle by tag:

```sh
updatecli manifest show "$OCI_REGISTRY/updatecli/autodiscovery:0.8.0"
```

## Troubleshooting

### No updates detected

1. Show the rendered manifest and verify that the `updatecli` crawler is present:

   ```sh
   updatecli manifest show --config updatecli.d --values values.yaml
   ```

2. Confirm that the repository contains an `updatecli-compose.yaml` file that references policy versions.

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
- Updatecli autodiscovery plugin docs: <https://www.updatecli.io/docs/plugins/autodiscovery/updatecli/>
- Updatecli policies repository: <https://github.com/updatecli/policies>