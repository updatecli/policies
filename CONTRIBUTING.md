# Contributing

Thank you for your interest in contributing to this project! This repository
hosts [Updatecli](https://www.updatecli.io) policies that are published as OCI
bundles to `ghcr.io/updatecli/policies`.

There are several ways to help:

- [Improve documentation](#documentation) for existing policies.
- [Update an existing policy](#updating-a-policy).
- [Add a new policy](#adding-a-new-policy).

## Documentation

This project benefits from clear, consistent policy `README.md` files. Each one
should explain what the policy does, how to use it, and how to configure it —
ideally with a short `values.yaml` example so users can get started quickly.

### Inspecting a policy locally

To inspect a policy bundle locally (its rendered manifest and default values):

```shell
# Show the generated manifest, using the files in the policy bundle directory
updatecli manifest show --config updatecli.d --values values.yaml

# Show the manifest and render a dependency graph (Mermaid)
updatecli manifest show --config updatecli.d --values values.yaml --graph --graph-flavor mermaid
```

- `--config updatecli.d` reads the policy manifests shipped inside the bundle.
- `--values values.yaml` overrides the default policy values for local inspection.

### Running a published policy

When running a published policy, pin it by version or digest to ensure
reproducible runs:

- By tag: `ghcr.io/updatecli/policies/autodiscovery/golang:1.0.0`
- By digest: `ghcr.io/updatecli/policies/autodiscovery/golang@sha256:<digest>`

Common commands:

| Action | Command |
| --- | --- |
| Inspect | `updatecli manifest show --config updatecli.d --values values.yaml` |
| Dry-run | `updatecli diff --config ghcr.io/updatecli/policies/<path>:<version>` |
| Apply | `updatecli apply --config ghcr.io/updatecli/policies/<path>:<version>` |

### Authentication

- Public pulls usually work anonymously, but authenticating with GHCR reduces
  rate limits:

  ```shell
  docker login ghcr.io
  ```

- For private bundles, provide registry credentials to your runtime or via
  Updatecli's registry authentication options.

## Updating a policy

Before changing an existing policy, open a
[GitHub issue](https://github.com/updatecli/policies/issues) to discuss the
proposed change. Use the issue to explain:

- Motivation and user impact.
- Backwards-compatibility implications.
- Required changes to `Policy.yaml`, `values.yaml`, or `updatecli.d`.
- Testing plan (how the change will be validated).

When preparing a pull request:

- Bump the `version` field in `Policy.yaml` for behavioural changes
  ([semantic versioning](https://semver.org)).
- Update `CHANGELOG.md` and the policy `README.md` with usage and configuration
  changes.
- Add or update `values.yaml` examples if the defaults change.
- Ensure the policy validation CI (lint and manifest tests) passes.

### Pull request checklist

- [ ] Issue opened describing the change (linked in the PR).
- [ ] `Policy.yaml` version updated when needed.
- [ ] `CHANGELOG.md` updated.
- [ ] `README.md` and example `values.yaml` updated.
- [ ] All CI checks pass (policy validation workflow).

> **Note**
> - Policies are published automatically by CI when `Policy.yaml`'s `version` is
>   updated.
> - For large or breaking changes, discuss a migration plan in the issue and
>   notify maintainers.
> - For security-related changes, include an explanation and coordinate
>   disclosure with maintainers.

## Adding a new policy

A new policy is added by creating a new folder under the `updatecli/policies`
directory. The subfolder path is used as the policy name.

For example, to create a policy named `autodiscovery/golang`, create the folder
`updatecli/policies/autodiscovery/golang`. It will be named and published as
`ghcr.io/updatecli/policies/autodiscovery/golang`.

The policy folder must contain:

| File / directory | Purpose |
| --- | --- |
| `Policy.yaml` | Policy metadata. |
| `updatecli.d/` | Policy configuration (manifest) files. |
| `README.md` | Policy documentation. |
| `CHANGELOG.md` | Policy changelog. |
| `values.yaml` | Default values for the policy. |

### `Policy.yaml`

The `Policy.yaml` file must contain at least the following fields:

```yaml
url: <link to this git repository>
documentation: <link to the policy documentation>
source: <link to this policy code>
version: <policy version>
changelog: <link to this policy changelog>
description: <policy description, maximum 512 characters>
```

### Versioning

The version must be a valid [semantic version](https://semver.org) — for
example `1.0.0` or `1.0.0-beta.1`. It is used as the tag for the policy, such as
`ghcr.io/updatecli/policies/autodiscovery/golang:1.0.0`.

Any change to the policy code must be reflected by a new version. Policies are
automatically published to `ghcr.io` when the version is updated.
