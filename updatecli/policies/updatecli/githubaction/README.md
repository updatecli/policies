# Updatecli GitHub Action Policy

Automatically update the `updatecli/updatecli-action` reference in GitHub Actions workflow files to the latest release, keeping both the pinned digest and the `with.version` field in sync.

## Overview

This policy runs **two** Updatecli pipelines:

1. **`action.yaml`** — updates the `uses:` field of `updatecli/updatecli-action` steps to the latest release tag digest:
   - Sets `uses: updatecli/updatecli-action@<digest>` with the version tag as a YAML comment
   - Targets path: `$.jobs.*.steps[?(@.uses =~ /^updatecli\/updatecli-action/)].uses`

2. **`action-version.yaml`** — updates the `with.version` field inside `updatecli/updatecli-action` steps to the latest Updatecli release:
   - Targets path: `$.jobs.*.steps[?(@.uses =~ /^updatecli\/updatecli-action/)].with.version`

Both pipelines scan `.github/workflows/*` files using `yamlpath` engine with `searchpattern: true`.

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

- `pipelineid`: optional pipeline identifier
- `automerge`: controls GitHub and GitHub search pull request automerge behavior
- `labels`: labels applied on GitHub and GitHub search pull requests
- `scm`: optional SCM configuration used to open pull requests
- `versionpattern`: semver pattern used to filter releases (default: `>0.0.0-0`)
- `github.env_token`: environment variable name holding the GitHub token (default: `GITHUB_TOKEN`)
- `github.env_username`: environment variable name holding the GitHub username (default: `GITHUB_ACTOR`)

### Example Values

The following example updates the Updatecli action reference and version in all workflow files and opens a pull request:

```yaml
pipelineid: "updatecli_gha"
automerge: false

labels:
  - chore
  - dependencies

versionpattern: ">0.0.0-0"

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

### Pipeline 1: action.yaml

Fetches both the latest release tag and its tag hash from `updatecli/updatecli-action`, then updates the `uses:` field to the pinned digest while storing the version as a comment:

```yaml
sources:
  updatecli:
    kind: githubrelease
    spec:
      owner: updatecli
      repository: updatecli-action
      versionfilter:
        kind: semver
        pattern: <versionpattern>

  updatecli-digest:
    kind: githubrelease
    spec:
      key: taghash
      owner: updatecli
      repository: updatecli-action

targets:
  githubaction:
    kind: yaml
    disablesourceinput: true
    spec:
      engine: yamlpath
      key: $.jobs.*.steps[?(@.uses =~ /^updatecli\/updatecli-action/)].uses
      value: updatecli/updatecli-action@<digest>
      comment: <version>
      files:
        - .github/workflows/*
      searchpattern: true
```

### Pipeline 2: action-version.yaml

Fetches the latest `updatecli/updatecli` release and updates the `with.version` field:

```yaml
sources:
  updatecli:
    kind: githubrelease
    spec:
      owner: updatecli
      repository: updatecli
      versionfilter:
        kind: semver
        pattern: <versionpattern>

targets:
  githubaction:
    kind: yaml
    spec:
      engine: yamlpath
      key: $.jobs.*.steps[?(@.uses =~ /^updatecli\/updatecli-action/)].with.version
      files:
        - .github/workflows/*
      searchpattern: true
```

If `scm.enabled` is `true`, both pipelines inject a `default` SCM and action to open pull requests.

## Quick Usage

### Local Testing

Show the rendered manifests:

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
updatecli manifest show --values values.yaml ghcr.io/updatecli/policies/updatecli/githubaction:0.8.0
```

```sh
updatecli pipeline diff --values values.yaml ghcr.io/updatecli/policies/updatecli/githubaction:0.8.0
```

```sh
updatecli pipeline apply --values values.yaml ghcr.io/updatecli/policies/updatecli/githubaction:0.8.0
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
  --tag "$OCI_REGISTRY/updatecli/githubaction" \
  .
```

After publishing, reference the bundle by tag:

```sh
updatecli manifest show "$OCI_REGISTRY/updatecli/githubaction:0.8.0"
```

## Troubleshooting

### No updates detected

1. Show the rendered manifests and verify the source and target configuration:

   ```sh
   updatecli manifest show --config updatecli.d --values values.yaml
   ```

2. Confirm that your workflow files use `updatecli/updatecli-action` with a `with.version` field.

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
- updatecli-action repository: <https://github.com/updatecli/updatecli-action>
- Updatecli policies repository: <https://github.com/updatecli/policies>
