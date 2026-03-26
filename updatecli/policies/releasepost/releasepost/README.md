# releasepost Policy

Synchronize release notes from GitHub releases to local files using the `releasepost` CLI tool, and optionally commit and open a pull request with any new release note files.

## Overview

This policy runs a single Updatecli pipeline that:

- executes `releasepost --detailed-exit-code --dry-run="$DRY_RUN" --config <configpath>` as a shell target
- uses exit code logic to determine whether changes were made (`0` = success/changed, `2` = warning/nothing to do, `1` = failure)
- optionally commits the resulting files and opens a pull request through a configured SCM backend

`releasepost` reads from a `.releasepost.yaml` configuration file to know which GitHub releases to sync and where to write output files. This policy wraps that tool to make it easy to run in a CI/CD pipeline and create pull requests automatically.

Setting `DRY_RUN=true` before running Updatecli causes `releasepost` to report what it would do without writing any files.

## Requirements

- `updatecli` CLI installed
- `releasepost` CLI installed and available on `PATH`
- a `.releasepost.yaml` configuration file in the target repository (or a custom path via `configpath`)
- a GitHub token available as an environment variable for `releasepost` to fetch release data
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
- `labels`: labels applied on GitHub and GitHub search pull requests (default: `documentation`)
- `configpath`: path to the `releasepost` configuration file (default: `.releasepost.yaml`)
- `releasedir`: directory where release note files are written (default: `content/en/changelogs/`)
- `scm`: optional SCM configuration used to open pull requests
- `github.env_token`: environment variable name holding the GitHub token passed to `releasepost` (default: `GITHUB_TOKEN`)

### Example Values

The following example runs `releasepost` and opens a pull request with new release note files:

```yaml
pipelineid: "releasepost"
automerge: false

labels:
  - documentation

configpath: ".releasepost.yaml"
releasedir: "content/en/changelogs/"

github:
  env_token: GITHUB_TOKEN

scm:
  enabled: true
  kind: github
  env_token: GITHUB_TOKEN
  user: updatecli-bot
  email: updatecli-bot@example.com
  owner: myorg
  repository: mysite
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
pipelineid: <pipelineid>

targets:
  default:
    name: synchronize release notes
    kind: shell
    spec:
      command: 'releasepost --detailed-exit-code --dry-run="$DRY_RUN" --config <configpath>'
      environments:
        - name: <github.env_token>
        - name: RELEASEPOST_GITHUB_TOKEN
        - name: PATH
      changedif:
        kind: exitcode
        spec:
          success: 0
          warning: 2
          failure: 1
```

The `changedif` block uses `releasepost`'s `--detailed-exit-code` flag: exit `0` means files were written, `2` means nothing changed (treated as a warning), and `1` means an error occurred.

If `scm.enabled` is `true`, the target is linked to the `default` SCM so that any written files are committed and a pull request is opened.

## Quick Usage

### Local Testing

Show the rendered manifest:

```sh
updatecli manifest show --config updatecli.d --values values.yaml
```

Run a dry-run (nothing is written to disk):

```sh
DRY_RUN=true updatecli pipeline diff --config updatecli.d --values values.yaml
```

Apply the policy and commit any new files:

```sh
updatecli pipeline apply --config updatecli.d --values values.yaml
```

### Using from an OCI Registry

Consume the published bundle directly from a registry:

```sh
updatecli manifest show --values values.yaml ghcr.io/updatecli/policies/releasepost/releasepost:0.11.0
```

```sh
DRY_RUN=true updatecli pipeline diff --values values.yaml ghcr.io/updatecli/policies/releasepost/releasepost:0.11.0
```

```sh
updatecli pipeline apply --values values.yaml ghcr.io/updatecli/policies/releasepost/releasepost:0.11.0
```

## Authentication

Authenticate to your OCI registry before pushing or pulling bundles:

```sh
docker login "$OCI_REGISTRY"
```

Export the GitHub token before running Updatecli (used by `releasepost` to fetch release data):

```sh
export GITHUB_TOKEN="ghp_xxxx"
```

When using SCM integration, also export the token referenced by `scm.env_token`.

## Publish

Publish this policy bundle to an OCI registry. The `version` field in `Policy.yaml` defines the bundle tag:

```sh
updatecli manifest push \
  --config updatecli.d \
  --values values.yaml \
  --policy Policy.yaml \
  --tag "$OCI_REGISTRY/releasepost/releasepost" \
  .
```

After publishing, reference the bundle by tag:

```sh
updatecli manifest show "$OCI_REGISTRY/releasepost/releasepost:0.11.0"
```

## Troubleshooting

### No updates detected

1. Show the rendered manifest and verify that the shell target is configured correctly:

   ```sh
   updatecli manifest show --config updatecli.d --values values.yaml
   ```

2. Confirm that `releasepost` is installed and on `PATH`:

   ```sh
   releasepost --version
   ```

3. Verify that the `configpath` file exists and contains valid `releasepost` configuration.

4. Run `releasepost` directly to check for errors:

   ```sh
   releasepost --detailed-exit-code --dry-run=true --config .releasepost.yaml
   ```

5. Run Updatecli in debug mode:

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
- releasepost repository: <https://github.com/updatecli/releasepost>
- Shell target plugin docs: <https://www.updatecli.io/docs/plugins/targets/shell/>
- Compose docs: <https://www.updatecli.io/docs/core/compose/>
- Sharing and reuse: <https://www.updatecli.io/docs/core/shareandreuse/>
- Updatecli policies repository: <https://github.com/updatecli/policies>
