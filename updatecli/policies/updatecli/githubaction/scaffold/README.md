# Updatecli GitHub Action Scaffold Policy

This policy installs — and then keeps up to date — the three Updatecli GitHub Action
workflows in your repositories.

## Overview

**Updatecli** is a tool for automating configuration updates across git repositories. To run
it in CI you need a workflow; this policy creates those workflows for you and re-renders
them on every run so their pinned action digests never go stale.

It installs:

| File | Trigger | What it does |
| --- | --- | --- |
| `.github/workflows/updatecli.yaml` | `release`, `workflow_dispatch`, `schedule` | `updatecli compose apply` — opens pull requests |
| `.github/workflows/updatecli_test.yaml` | `pull_request` | `updatecli compose diff` — read-only dry run |
| `.github/workflows/updatecli_update.yaml` | `workflow_dispatch`, `push` to main, `schedule` | `updatecli compose apply` over a job matrix — refreshes pull requests that already exist |

Every `uses:` is pinned to a commit digest with the human-readable tag kept as a trailing
comment, and the `updatecli-action` `with.version` input tracks the latest Updatecli release.

## Read this before you run it

**1. These workflows become policy-owned files.** The targets use `forcecreate: true` with a
template, which rewrites each file in full on every run. That is what keeps the digests
current — but it also means any hand-edit you make to a scaffolded workflow is reverted on
the next run. To customise a workflow, fork the asset template and point `template_path` at
your copy (see [Customisation](#customisation)).

**2. Do not run this policy alongside
`ghcr.io/updatecli/policies/updatecli/githubaction`.** That policy patches `.uses` and
`.with.version` in `.github/workflows/*` with the yaml/yamlpath engine, which re-serialises
the document. This policy rewrites the same files wholesale from a template. Run both and
they will fight — each reverting the other, opening a pull request on every run, forever.
Pick one:

- **this policy** if you want Updatecli to own the workflow files end to end;
- **`updatecli/githubaction`** if the workflows are yours and you only want the version
  bumped.

**3. The workflows require an `updatecli-compose.yaml`.** All three run `updatecli compose`,
which exits with an error when that file is missing. This policy does **not** create one —
add it to your repository yourself, or the scheduled runs will fail. See the
[compose documentation](https://www.updatecli.io/docs/core/compose/).

**4. Committing to `.github/workflows/` needs elevated credentials.** `values.yaml` sets
`scm.commitusingapi: true`, so the token running *this policy* must be a PAT with the
`workflow` scope, or a GitHub App with `Workflows: write`. Without it the pull request fails
to push.

## Requirements

- `updatecli` installed (recommended: latest stable release).
- A **GitHub token** for the policy itself, with `repo` and `workflow` scopes, in the
  environment variable named by `scm.env_token` (default `GITHUB_TOKEN`). For
  `scm.kind: gitea`, a Gitea token with repository write access instead.
- An `updatecli-compose.yaml` in each target repository (see above).

## Policy configuration

### Choosing credentials for the generated workflows

`gha.auth` decides which secrets the generated apply/update workflows reference. This is
about the workflows this policy *writes*, not about the token the policy itself uses.

| `gha.auth` | Generated `env:` | Notes |
| --- | --- | --- |
| `app` (default) | `UPDATECLI_GITHUB_APP_CLIENT_ID`, `_PRIVATE_KEY`, `_INSTALLATION_ID` from `UPDATECLIBOT_APP_*` secrets | Matches the workflows the Updatecli project runs. **The workflows fail until those secrets exist in the target repository.** |
| `token` | `UPDATECLI_GITHUB_TOKEN` from `secrets.GITHUB_TOKEN`, plus a job-level `contents: write` / `pull-requests: write` grant | Works with no setup, but pull requests opened with `GITHUB_TOKEN` **do not trigger other workflows**, and the repository must allow Actions to create pull requests. |
| `gitea` | `UPDATECLI_GITEA_TOKEN` from `secrets.GITEA_TOKEN` | For workflows running on Gitea Actions, which provides `GITEA_TOKEN` automatically. |

Use `app` for an organisation that already has the bot app installed, `token` for a GitHub
repository that should work immediately, and `gitea` when the workflows run on Gitea.

### Gitea

The policy works with Gitea on both sides: it can open pull requests against Gitea
repositories, and it can generate workflows that run on Gitea Actions.

```yaml
scm:
  enabled: true
  kind: gitea
  url: "https://codeberg.org"   # required for gitea
  owner: myorg
  repository: myrepo
  branch: main
  env_token: GITEA_TOKEN

gha:
  auth: gitea
  workflow_dir: ".gitea/workflows"   # optional, .github/workflows also works
```

Four things to know:

- **`scm.url` is required** by the Gitea SCM, and `scm.env_token` should name a Gitea token
  (typically `GITEA_TOKEN`) rather than the `GITHUB_TOKEN` default.
- **The Gitea pull request action supports only a title and a body.** `labels`, `automerge`,
  `mergemethod` and `parent` are silently ignored for `scm.kind: gitea`.
- **`workflow_dir` is optional.** Gitea Actions reads both `.github/workflows` and
  `.gitea/workflows`; set it to the latter if you want Gitea workflows kept separate.
- **Check your instance's `DEFAULT_ACTIONS_URL`.** The generated workflows pin
  `actions/checkout` and `updatecli/updatecli-action` to github.com commit digests. Gitea's
  runner resolves bare `actions/...` from github.com by default, so this works out of the
  box — but on an instance pointed at gitea.com those digests refer to different
  repositories and the `uses:` lines will not resolve.

### Udash reporting

`gha.udash.enabled` is off by default. Turning it on does two things to the generated apply
and update workflows: it renders the three `UPDATECLI_UDASH_*` environment variables, and it
appends `--experimental` to the `updatecli compose apply` command — Udash publishing is gated
behind that flag. With Udash off, the workflows run without `--experimental`, since nothing
else they do requires it.

### Adding a language runtime

Both are off by default and independent — enable either, both, or neither.

```yaml
gha:
  golang:
    enabled: true
    version_file: "go.mod"      # actions/setup-go go-version-file
  npm:
    enabled: true
    version_file: "package.json" # actions/setup-node node-version-file
```

When a runtime is disabled, its `actions/setup-*` sources are not even declared, so no
GitHub API calls are made for it.

### Full example

```yaml
scm:
  enabled: true
  kind: githubsearch
  search: |
    org:myorg
    archived:false
  branch: "^main$"
  email: bot@example.com
  limit: 5

pipelineid: "scaffold_updatecli"

gha:
  auth: token
  golang:
    enabled: true
  udash:
    enabled: false
```

### All values

| Value | Default | Purpose |
| --- | --- | --- |
| `gha.auth` | `app` | `app`, `token` or `gitea` — see above |
| `gha.workflow_dir` | `.github/workflows` | directory the workflows are written to |
| `gha.golang.enabled` / `.version_file` | `false` / `go.mod` | add an `actions/setup-go` step |
| `gha.npm.enabled` / `.version_file` | `false` / `package.json` | add an `actions/setup-node` step |
| `gha.udash.enabled` | `false` | render the `UPDATECLI_UDASH_*` variables and pass `--experimental` |
| `gha.apply.enabled` / `.cron` | `true` / `0 12 */14 * *` | the apply workflow |
| `gha.test.enabled` | `true` | the pull-request dry-run workflow |
| `gha.update.enabled` / `.cron` | `true` / `0 1 * * *` | the update workflow |
| `gha.update.matrix` | one `--existing-only=true` leg | job matrix of the update workflow |
| `gha.<workflow>.template_path` | raw URL on `main` | where the asset template is fetched from |

> **Scheduling.** If you scaffold this across a whole organisation, vary `gha.apply.cron`
> and `gha.update.cron` so every repository does not wake up at the same minute.

### The update workflow matrix

`gha.update.matrix` defaults to a single leg that only refreshes pull requests that already
exist — opening new ones is the apply workflow's job:

```yaml
gha:
  update:
    matrix:
      - target_name: "existing pipelines"
        apply_args: "--existing-only=true"
```

The Updatecli project itself adds a second leg restricted to manifests labelled
`monitor: active`. That leg matches nothing in a repository that does not use the
convention, so it is not the default:

```yaml
      - target_name: "monitored pipelines"
        apply_args: "--labels=monitor:active"
```

## Quick usage

### Local testing

```sh
export GITHUB_TOKEN="your_github_token"

# Inspect the rendered manifest
updatecli manifest show --config updatecli.d --values values.yaml

# Dry run against the current directory (scm.enabled: false)
updatecli diff --config updatecli.d --values values.yaml
```

### From the OCI registry

```sh
updatecli manifest show --values values.yaml ghcr.io/updatecli/policies/updatecli/githubaction/scaffold
updatecli diff        --values values.yaml ghcr.io/updatecli/policies/updatecli/githubaction/scaffold
updatecli apply       --values values.yaml ghcr.io/updatecli/policies/updatecli/githubaction/scaffold
```

Pin by tag or digest for reproducible runs:

```sh
updatecli apply --values values.yaml ghcr.io/updatecli/policies/updatecli/githubaction/scaffold:0.1.0
```

## Customisation

### Modify the generated workflows

The workflow templates live in `assets/` and are **fetched over HTTPS at run time** from
`raw.githubusercontent.com` on the `main` branch — they are not part of the OCI bundle. To
change what gets generated, host your own copy and override the path:

```yaml
gha:
  apply:
    template_path: "https://raw.githubusercontent.com/myorg/myrepo/main/my_updatecli.yaml"
```

The templates are Go templates rendered with [sprig](https://masterminds.github.io/sprig/).
Two things to know when editing one:

- GitHub Actions expressions must be escaped, or Go's template parser rejects the file:
  write `{{ "${{ secrets.GITHUB_TOKEN }}" }}`, not `${{ secrets.GITHUB_TOKEN }}`.
- Optional blocks test for the *presence* of a key — `{{- if .setupGoActionDigest }}` — so a
  disabled feature simply omits the value.

## Troubleshooting

**Workflow not created.** Check the token has both `repo` and `workflow` scopes; committing
into `.github/workflows/` fails without the latter. Then:

```sh
updatecli diff --log-level debug --config updatecli.d --values values.yaml
```

**A pull request is opened on every run.** Something else is rewriting the same files —
almost always the `updatecli/githubaction` bump policy. See point 2 above.

**The scheduled workflow fails with a compose error.** The repository has no
`updatecli-compose.yaml`. See point 3 above.

**`failed to read template file … 404`.** `template_path` points at a file that does not
exist on `main` yet. When developing this policy, point it at your branch temporarily, and
restore the `main` URL before merging.

## Links

- Updatecli documentation: <https://www.updatecli.io>
- Compose: <https://www.updatecli.io/docs/core/compose/>
- Sharing & reuse: <https://www.updatecli.io/docs/core/shareandreuse/>
- Updatecli GitHub Action: <https://github.com/updatecli/updatecli-action>
- Updatecli Policies: <https://github.com/updatecli/policies>
