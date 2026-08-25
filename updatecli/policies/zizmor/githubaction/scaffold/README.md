# Zizmor GitHub Action Policy

This policy scaffolds a Zizmor GitHub Action workflow for security scanning in your repositories.

## Overview

**Zizmor** is a static analysis tool that identifies misconfigurations in GitHub Actions workflows, helping you catch security issues early.

**Updatecli** is a tool for automating configuration updates across multiple repositories. This policy uses Updatecli to intelligently deploy Zizmor security scanning to your GitHub Action workflows.

The policy will only create a new Zizmor workflow if:

- Your repository has existing GitHub Actions workflows

## HOW IT WORKS

This policy implements a three-step process:

**Deployment**: Creates `.github/workflows/zizmor.yaml` with the latest Zizmor action version and compatible checkout action

The workflow runs on all pull requests and provides security analysis results directly in your PR comments.

**Remediation (optional)**: When `autofix.enabled` is set, the policy also runs `zizmor --fix` on
the repository and commits the result to the same branch, so the pull request installs the scanner
*and* fixes what it would have reported. See [AUTOMATIC REMEDIATION](#automatic-remediation).

## REQUIREMENTS

- `updatecli` CLI installed (recommended: latest stable release)
- Access to an OCI registry (set the `OCI_REGISTRY` environment variable)
- Optional: `docker` (or another OCI client) for logging in and pulling/pushing policy
- **GitHub Token** (`UPDATECLI_GITHUB_TOKEN`): Personal access token with scopes:
  - `repo` (full control of private repositories)
  - `workflow` (read/write GitHub Actions workflows)
- **GitHub Username** (`UPDATECLI_GITHUB_USERNAME`): GitHub account username for commit attribution
- Only when `autofix.enabled` is set: the [`zizmor`](https://docs.zizmor.sh/installation/) CLI,
  available in the `PATH` of the machine running Updatecli

## POLICY CONFIGURATION

### Available Input Values

Create a `values.yaml` file to customize the policy:

```yaml
# Required: SCM configuration to target repositories
scm:
  enabled: true
  kind: githubsearch
  search: |
    repo:myorg/repo1
    repo:myorg/repo2
    fork:true
  branch: "^main$"
  email: your-bot@example.com
  limit: 0  # 0 = no limit

# Optional: Override pipelineId
pipelineid: "zizmor-scaffold"
```

Tips: you can adjust the `search` field to target specific repositories, branches, or include forks as needed. More information
on [GitHub](https://github.com/search/advanced)

## AUTOMATIC REMEDIATION

Installing the scanner on a repository that was never audited means the first workflow run
reports findings that somebody then has to fix by hand. This policy can close that gap: with
`autofix` enabled, it runs `zizmor --fix` against the repository and commits the result to the
branch it just created, so a single pull request installs Zizmor **and** lands green.

The fixes are produced by Zizmor itself, not by a heuristic of this policy: the diff is
deterministic and reviewable like any other commit in the pull request.

```yaml
autofix:
  # Disabled by default: opt in explicitly.
  enabled: true

  # safe | all | unsafe-only
  mode: safe

  # What Zizmor audits and fixes.
  inputs: "./.github/"

  # Environment variable holding the token handed over to Zizmor.
  env_token: GITHUB_TOKEN
```

### Fix modes

| Mode | What it applies |
| --- | --- |
| `safe` (default) | Only fixes with a low breakage risk, safe to apply with minimal oversight |
| `all` | Safe **and** unsafe fixes |
| `unsafe-only` | Only the unsafe fixes |

Unsafe fixes are often correct but Zizmor makes no guarantee about their semantics — **always
review them** before merging. Sticking to `safe` is the recommended default for unattended runs.

Be aware that `safe` is conservative: Zizmor frequently classifies the two most common hardening
fixes — pinning an action to a digest (`unpinned-uses`) and adding `persist-credentials: false`
(`artipacked`) — as unsafe, and holds them back. On a repository that was never audited, `safe`
may therefore report findings without changing anything, and Zizmor tells you so:

```console
No fixes available to apply (2 held back by safe mode). Use --fix=unsafe-only or --fix=all to apply unsafe fixes.
```

Use `mode: all` when you want those applied, and review the resulting commit.

Findings that Zizmor cannot fix automatically — such as `template-injection` or
`excessive-permissions` — are left untouched and reported by the scaffolded workflow as usual.

### Requirements and behaviour

- The `zizmor` CLI must be installed on the machine running Updatecli. The policy fails with an
  explicit `zizmor CLI not found in PATH` message when it is missing.
- Fixes land as an **additional commit** on the branch, after the one installing the workflow.
- A repository with nothing to fix produces no extra commit; the pipeline simply reports no change.
- Some fixes, such as those of the `unpinned-uses` audit, query the GitHub API. The token named by
  `autofix.env_token` is passed through for that purpose.

## QUICK USAGE

### Local Testing

Set up your environment:

```sh
export UPDATECLI_GITHUB_TOKEN="your_github_token"
export UPDATECLI_GITHUB_USERNAME="your_github_username"
```

Show the policy manifest (parse configuration):

```sh
updatecli manifest show --config updatecli.d --values values.yaml
```

Dry-run to see what changes would be made:

```sh
updatecli pipeline diff --config updatecli.d --values values.yaml
```

Apply the policy (create the Zizmor workflow):

```sh
updatecli pipeline apply --config updatecli.d --values values.yaml
```

### Using from OCI Registry

After publishing (see PUBLISH section), use the policy from a registry:

Show the policy:

```sh
updatecli manifest show --values values.yaml  ghcr.io/updatecli/policies/zizmor/githubaction/scaffold
```

Dry-run:

```sh
updatecli pipeline diff --values values.yaml ghcr.io/updatecli/policies/zizmor/githubaction/scaffold
```

Apply:

```sh
updatecli pipeline apply --values values.yaml ghcr.io/updatecli/policies/zizmor/githubaction/scaffold
```

## AUTHENTICATION

Authenticate with your OCI registry before publishing or pulling private bundles:

```sh
docker login "$OCI_REGISTRY"
```

`OCI_REGISTRY` can be any OCI-compliant registry (for example: Zot, Docker Hub, GitHub Container Registry).

## PUBLISH

Publish the bundle to an OCI registry (the `version` field in `Policy.yaml` controls the tag):

```sh
updatecli manifest push \
  --config updatecli.d \
  --values values.yaml \
  --policy Policy.yaml \
  --tag "$OCI_REGISTRY/<policy-name>" \
  .
```

After publishing, reference the bundle by tag:

```sh
updatecli manifest show "$OCI_REGISTRY/<policy-name>:v1.0.0"
```

## TROUBLESHOOTING

### Workflow not created?

1. **Verify conditions are met:**

   ```sh
   updatecli manifest show --config updatecli.d --values values.yaml
   ```

   Check the output to confirm both conditions pass:
   - GitHub Actions workflows exist in `.github/workflows/`
   - Zizmor is not already configured

2. **Check GitHub token permissions:**
   - Ensure token has `repo` and `workflow` scopes
   - Verify token has write access to target repositories

3. **Debug mode:**

   ```sh
   updatecli pipeline diff --log-level debug --config updatecli.d --values values.yaml
   ```

### Workflow exists but not executing?

- The Zizmor workflow triggers on `pull_request` events by default
- Open a pull request to the repository to see it in action
- Check the workflow runs in the repository's **Actions** tab

## CUSTOMIZATION

### Modify the generated workflow

Edit the template asset to customize Zizmor behavior:

- **Template location**: `assets/gha_security_analysis.yaml`
- After editing, republish the policy bundle (see PUBLISH section)

### Common customizations

- **Change trigger events**: Modify the `on:` section in the template
- **Add additional scanning jobs**: Extend the workflow steps
- **Configure Zizmor options**: Adjust the `with:` parameters for the Zizmor action

### Update policy version

Increment the `version` field in `Policy.yaml` before republishing to track changes.

## NEXT STEPS & LINKS

- Official docs: <https://www.updatecli.io>
- Compose docs (orchestrating multiple policies): <https://www.updatecli.io/docs/core/compose/>
- Sharing & reuse: <https://www.updatecli.io/docs/core/shareandreuse/>
- Zizmor GitHub Action: <https://github.com/zizmorcore/zizmor-action>
- Updatecli Policies: <https://github.com/updatecli/policies>
