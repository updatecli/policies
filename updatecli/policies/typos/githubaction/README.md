# Typos GitHub Action Policy

This policy scaffolds a typos GitHub Action workflow for spell checking in your repositories.

## Overview

**typos** is a fast source code spell checker that finds and fixes typos in source code and documentation.

**Updatecli** is a tool for automating configuration updates across multiple repositories. This policy uses Updatecli to intelligently deploy typos spell checking to your GitHub Action workflows.

The policy will create a new typos workflow and, if configured, a `_typos.toml` configuration file.

## HOW IT WORKS

This policy implements a two-step process:

**Deployment**: Creates `.github/workflows/typos.yaml` with the latest typos action version and compatible checkout action.

**Configuration** (optional): Creates `_typos.toml` with your custom typos configuration when the `config` value is set.

The workflow runs on all pull requests and pushes to main, checking for typos in the repository.

## REQUIREMENTS

- `updatecli` CLI installed (recommended: latest stable release)
- Access to an OCI registry (set the `OCI_REGISTRY` environment variable)
- Optional: `docker` (or another OCI client) for logging in and pulling/pushing policy
- **GitHub Token** (`UPDATECLI_GITHUB_TOKEN`): Personal access token with scopes:
  - `repo` (full control of private repositories)
  - `workflow` (read/write GitHub Actions workflows)
- **GitHub Username** (`UPDATECLI_GITHUB_USERNAME`): GitHub account username for commit attribution

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
pipelineid: "gha_typos"

# Optional: provide a typos configuration file content
#config: |
#  [files]
#  extend-exclude = [
#    "go.mod",
#    "_typos.toml"
#  ]
```

Tips: you can adjust the `search` field to target specific repositories, branches, or include forks as needed. More information
on [GitHub](https://github.com/search/advanced)

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

Apply the policy (create the typos workflow):

```sh
updatecli pipeline apply --config updatecli.d --values values.yaml
```

### Using from OCI Registry

After publishing (see PUBLISH section), use the policy from a registry:

Show the policy:

```sh
updatecli manifest show --values values.yaml  ghcr.io/updatecli/policies/typos/githubaction
```

Dry-run:

```sh
updatecli pipeline diff --values values.yaml ghcr.io/updatecli/policies/typos/githubaction
```

Apply:

```sh
updatecli pipeline apply --values values.yaml ghcr.io/updatecli/policies/typos/githubaction
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

2. **Check GitHub token permissions:**
   - Ensure token has `repo` and `workflow` scopes
   - Verify token has write access to target repositories

3. **Debug mode:**

   ```sh
   updatecli pipeline diff --log-level debug --config updatecli.d --values values.yaml
   ```

### Workflow exists but not executing?

- The typos workflow triggers on `pull_request` events and pushes to `main` by default
- Open a pull request to the repository to see it in action
- Check the workflow runs in the repository's **Actions** tab

## CUSTOMIZATION

### Modify the generated workflow

Edit the template asset to customize typos behavior:

- **Template location**: `assets/gha_typos.yaml`
- After editing, republish the policy bundle (see PUBLISH section)

### Common customizations

- **Change trigger events**: Modify the `on:` section in the template
- **Add custom word list**: Use the `config` value to provide a `_typos.toml` configuration
- **Configure typos options**: Adjust the `with:` parameters for the typos action

### Update policy version

Increment the `version` field in `Policy.yaml` before republishing to track changes.

## NEXT STEPS & LINKS

- Official docs: <https://www.updatecli.io>
- Compose docs (orchestrating multiple policies): <https://www.updatecli.io/docs/core/compose/>
- Sharing & reuse: <https://www.updatecli.io/docs/core/shareandreuse/>
- typos GitHub Action: <https://github.com/crate-ci/typos>
- Updatecli Policies: <https://github.com/updatecli/policies>
