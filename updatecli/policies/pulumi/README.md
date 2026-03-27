# Pulumi SDK Alignment Policy

> **⚠️ Demo / Prototype**: This policy is written for demonstration purposes and may be relocated or refactored.

Align the `github.com/pulumi/pulumi/pkg/v3` and `github.com/pulumi/pulumi/sdk/v3` Go module versions in a Pulumi provider with the versions used by `pulumi-terraform-bridge`.

## Overview

This policy runs **two** Updatecli pipelines:

1. **`pulumi-pkg.yaml`** — bumps `github.com/pulumi/pulumi/pkg/v3` in `provider/go.mod` to the version used by `pulumi-terraform-bridge`
2. **`pulumi-sdk.yaml`** — bumps `github.com/pulumi/pulumi/sdk/v3` in `provider/go.mod` to the version used by `pulumi-terraform-bridge`

Both pipelines follow the same pattern:

- read the current `pulumi-terraform-bridge` version from `provider/go.mod`
- fetch the bridge's own `go.mod` from GitHub to determine the exact Pulumi SDK version it uses
- check that the corresponding Pulumi package is already declared in `provider/go.mod`
- update it to match the bridge's version

This ensures that the provider and bridge always use the same core Pulumi SDK version, preventing subtle version mismatches that can cause build or runtime failures.

## Requirements

- `updatecli` CLI installed
- `UPDATECLI_GITHUB_TOKEN` environment variable set to a GitHub token with read access
- `UPDATECLI_GITHUB_ACTOR` environment variable set to the GitHub username for authentication
- a `provider/go.mod` file that declares both `pulumi-terraform-bridge` and the Pulumi SDK packages
- access to an OCI registry if you want to publish or consume the bundle from a registry
- optional: `docker` or another OCI client for registry authentication

## Supported SCM Backends

This policy always uses GitHub as its SCM backend. It requires:

- `UPDATECLI_GITHUB_TOKEN`: GitHub personal access token with repo write access
- `UPDATECLI_GITHUB_ACTOR`: GitHub username used for authentication

## Policy Configuration

### Available Input Values

The default `values.yaml` exposes these top-level inputs:

- `scm.default.owner`: GitHub organization or user owning the destination repository
- `scm.default.repository`: destination repository name
- `scm.default.branch`: branch to target (default: `main`)
- `scm.default.user`: git commit author name
- `scm.default.email`: git commit author email
- `labels`: list of labels applied to pull requests

### Example Values

```yaml
scm:
  default:
    owner: myorg
    repository: pulumi-provider-mything
    branch: main
    user: updatecli-bot
    email: updatecli-bot@example.com

labels:
  - dependencies
```

## How It Works

Each pipeline reads the bridge version from the local `provider/go.mod`, then fetches the bridge's own `go.mod` at that tag from GitHub raw content to resolve the exact Pulumi package version:

```yaml
sources:
  bridge:
    scmid: default
    kind: golang/gomod
    spec:
      file: provider/go.mod
      module: github.com/pulumi/pulumi-terraform-bridge/v3

  pulumi/pkg:
    kind: golang/gomod
    dependson:
      - bridge
    spec:
      file: https://raw.githubusercontent.com/pulumi/pulumi-terraform-bridge/<bridge-version>/go.mod
      module: github.com/pulumi/pulumi/pkg/v3

conditions:
  pulumi/pkg:
    scmid: default
    kind: golang/gomod
    spec:
      file: provider/go.mod
      module: github.com/pulumi/pulumi/pkg/v3

targets:
  pulumi/pkg:
    scmid: default
    kind: golang/gomod
    spec:
      file: provider/go.mod
      module: github.com/pulumi/pulumi/pkg/v3
```

GitHub credentials are always taken from `UPDATECLI_GITHUB_TOKEN` and `UPDATECLI_GITHUB_ACTOR` environment variables using `requiredEnv`. The SCM values block controls the repository written to.

## Quick Usage

### Prerequisites

```sh
export UPDATECLI_GITHUB_TOKEN="ghp_xxxx"
export UPDATECLI_GITHUB_ACTOR="myusername"
```

### Local Testing

Show the rendered manifests:

```sh
updatecli manifest show --config updatecli.d --values values.yaml
```

Run a dry-run:

```sh
updatecli pipeline diff --config updatecli.d --values values.yaml
```

Apply the policy through the configured SCM action:

```sh
updatecli pipeline apply --config updatecli.d --values values.yaml
```

### Using from an OCI Registry

Consume the published bundle directly from a registry:

```sh
updatecli manifest show --values values.yaml ghcr.io/updatecli/policies/pulumi:0.6.0
```

```sh
updatecli pipeline diff --values values.yaml ghcr.io/updatecli/policies/pulumi:0.6.0
```

```sh
updatecli pipeline apply --values values.yaml ghcr.io/updatecli/policies/pulumi:0.6.0
```

## Authentication

Authenticate to your OCI registry before pushing or pulling bundles:

```sh
docker login "$OCI_REGISTRY"
```

Always export the required GitHub environment variables before running Updatecli:

```sh
export UPDATECLI_GITHUB_TOKEN="ghp_xxxx"
export UPDATECLI_GITHUB_ACTOR="myusername"
```

## Publish

Publish this policy bundle to an OCI registry. The `version` field in `Policy.yaml` defines the bundle tag:

```sh
updatecli manifest push \
  --config updatecli.d \
  --values values.yaml \
  --policy Policy.yaml \
  --tag "$OCI_REGISTRY/pulumi" \
  .
```

After publishing, reference the bundle by tag:

```sh
updatecli manifest show "$OCI_REGISTRY/pulumi:0.6.0"
```

## Troubleshooting

### No updates detected

1. Confirm that `provider/go.mod` declares `github.com/pulumi/pulumi-terraform-bridge/v3`.

2. Confirm that `provider/go.mod` also declares `github.com/pulumi/pulumi/pkg/v3` and `github.com/pulumi/pulumi/sdk/v3` — the condition step requires them to be present.

3. Run in debug mode:

   ```sh
   updatecli pipeline diff --log-level debug --config updatecli.d --values values.yaml
   ```

### Pull requests are not created

1. Verify that `UPDATECLI_GITHUB_TOKEN` and `UPDATECLI_GITHUB_ACTOR` are exported.

2. Confirm that `scm.default.owner` and `scm.default.repository` are set to the correct values.

3. Ensure the token has write access to the target repository.

## Related Documentation

- Updatecli docs: <https://www.updatecli.io>
- Golang/gomod target plugin docs: <https://www.updatecli.io/docs/plugins/targets/golang/gomod/>
- Compose docs: <https://www.updatecli.io/docs/core/compose/>
- Sharing and reuse: <https://www.updatecli.io/docs/core/shareandreuse/>
- pulumi-terraform-bridge repository: <https://github.com/pulumi/pulumi-terraform-bridge>
- Updatecli policies repository: <https://github.com/updatecli/policies>
