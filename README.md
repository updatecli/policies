<p align="center">
  <img src="https://www.updatecli.io/images/updatecli.png" alt="Updatecli" width="400">
</p>
<p align="center">
  <a href="https://matrix.to/#/#Updatecli_community:gitter.im"><img src="https://img.shields.io/matrix/updatecli:matrix.org" alt="Matrix chat"></a>
  <a href="./LICENSE"><img src="https://img.shields.io/github/license/updatecli/policies" alt="License"></a>
  <a href="https://github.com/updatecli/policies/actions/workflows/validate.yaml"><img src="https://img.shields.io/github/actions/workflow/status/updatecli/policies/validate.yaml?branch=main" alt="Build status"></a>
</p>
Updatecli Policies
 
The official collection of reusable [Updatecli](https://github.com/updatecli/updatecli)
policies, published as OCI artifacts to `ghcr.io/updatecli/policies`.
 
Instead of copying the same update manifest into every repository you own, you
pull a versioned policy from a registry and point it at your project.
 
**→ [Browse the full policy catalogue](./POLICIES.md)**
 
---
 
## What is an Updatecli policy?
 
An Updatecli policy is a **bundle** — one or more Updatecli manifests plus their
values and secrets files — described by a `Policy.yaml` file and published to an
OCI registry such as `ghcr.io`, Docker Hub, or Quay. Despite the
container-shaped reference, a policy is not a container image: it is an OCI
artifact where each layer holds one of the bundled files.
 
If you are new to the concept, read this first:
 
**📖 [Updatecli Policy — share and reuse](https://www.updatecli.io/docs/core/shareandreuse/)**
 
That page explains the `Policy.yaml` schema, how versioning works, and how to
publish your own policies. This repository is the reference implementation of
everything described there.
 
### Why use a shared policy instead of a local manifest?
 
- **Write once, run everywhere.** Enforce the same Golang version across an
  entire GitHub organisation without duplicating a manifest per repository.
- **Versioned and upgradable.** Policies follow semantic versioning, so
  consuming projects can adopt changes at their own pace rather than being
  broken by an edit to a shared file.
- **Parameterisable.** The same policy can run with different values on
  different schedules — patch updates weekly, major updates monthly — by
  overriding values at runtime.
- **Auditable.** A policy reference is a single line in your repository. What it
  does is inspectable before you run it (see [Inspect before you
  run](#inspect-before-you-run)).
---
 
## Requirements
 
- [Updatecli](https://www.updatecli.io/docs/prologue/installation/) installed
  locally, or the
  [updatecli-action](https://github.com/updatecli/updatecli-action) in CI.
- A Docker-compatible login to `ghcr.io`. Updatecli does not manage registry
  credentials itself — it reads your local Docker configuration, so you must
  authenticate before any registry operation:
```shell
  docker login ghcr.io
```
 
---
 
## Quick start
 
> **A note on flags.** A policy reference is passed as the last positional
> argument, never with `--config`. That flag is for local manifest files and
> directories only. `updatecli compose` is separate again and takes `--file`.
>
> ```shell
> updatecli diff ghcr.io/updatecli/policies/autodiscovery/golang:0.13.1  # ✅
> updatecli diff --config ghcr.io/updatecli/policies/autodiscovery/golang:0.13.1  # ❌
> updatecli diff --config ./updatecli/updatecli.d  # ✅ local manifest
> ```
 
### Inspect before you run
 
A policy will modify files in your repository and may open pull requests. Read
it first:
 
```shell
updatecli manifest show ghcr.io/updatecli/policies/autodiscovery/golang:0.13.1
```
 
### See what would change
 
`diff` performs no writes. This is the command to reach for while evaluating a
policy:
 
```shell
updatecli diff ghcr.io/updatecli/policies/autodiscovery/golang:0.13.1
```
 
### Apply it
 
```shell
updatecli apply ghcr.io/updatecli/policies/autodiscovery/golang:0.13.1
```
 
---
 
## Pinning versions
 
**Policy tags are mutable.** A published version can be overwritten, so
`:0.13.1` today is not guaranteed to be byte-identical to `:0.13.1` tomorrow,
and `:latest` will silently move underneath you.
 
For anything running unattended in CI, pin to a digest:
 
```shell
updatecli apply ghcr.io/updatecli/policies/autodiscovery/golang:0.13.1@sha256:<digest>
```
 
Resolve the digest for a tag with:
 
```shell
docker buildx imagetools inspect ghcr.io/updatecli/policies/autodiscovery/golang:0.13.1
```
 
Guidance by context:
 
| Context | Recommended reference |
| --- | --- |
| Local experimentation | `:latest` |
| Everyday CI | `:0.13.1` (explicit semver) |
| Regulated / high-trust CI | `:0.13.1@sha256:...` (digest) |
 
<!-- TODO: if the release workflow signs artifacts with cosign, document
     `cosign verify` here. If it does not yet, consider adding it — signing is
     called out in the upstream docs as one of the benefits of the OCI
     approach, and these bundles hold write access to consumers' repositories.
     Delete this block if not applicable. -->
 
---
 
## Running several policies together
 
`updatecli compose` runs a set of policies from a single file. Create
`updatecli-compose.yaml`:
 
```yaml
policies:
  - name: Keep Go toolchain and modules up to date
    policy: ghcr.io/updatecli/policies/autodiscovery/golang:0.13.1
  - name: Keep npm dependencies up to date
    policy: ghcr.io/updatecli/policies/autodiscovery/npm:0.14.1
```
 
Then:
 
```shell
# Preview
updatecli compose diff --file updatecli-compose.yaml
 
# Apply
updatecli compose apply --file updatecli-compose.yaml
```
 
Values supplied at runtime override the bundle defaults. See each policy's own
README — linked from [POLICIES.md](./POLICIES.md) — for the values it accepts.
 
Full reference: [Compose documentation](https://www.updatecli.io/docs/core/compose/).
 
---
 
## Running in GitHub Actions
 
```yaml
name: Updatecli
on:
  schedule:
    - cron: "0 6 * * 1"
  workflow_dispatch:
 
permissions:
  contents: write
  pull-requests: write
 
jobs:
  updatecli:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: updatecli/updatecli-action@v2
      - run: updatecli compose apply --file updatecli-compose.yaml
        env:
          UPDATECLI_GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          UPDATECLI_GITHUB_ACTOR: ${{ github.actor }}
```
 
Grant the smallest token scope the policy actually needs. A policy that only
opens pull requests does not need push access to protected branches.
 
---
 
## Developing a policy locally
 
Policies live under `updatecli/policies/<name>/`. To render one from source
without publishing it:
 
```shell
updatecli manifest show \
  --config ./updatecli/policies/<name>/updatecli.d \
  --values ./updatecli/policies/<name>/values.yaml
```
 
Render its dependency graph:
 
```shell
updatecli manifest show \
  --config ./updatecli/policies/<name>/updatecli.d \
  --values ./updatecli/policies/<name>/values.yaml \
  --graph --graph-flavor mermaid
```
 
Repository-level tasks:
 
```shell
make help       # list available targets
make test       # validate that every policy is publishable
make e2e-test   # run end-to-end tests
```
 
---
 
## Publishing
 
CI publishes a policy automatically when the `version` field in its
`Policy.yaml` changes on `main`. Versions must be semver-compliant **without** a
leading `v`.
 
When changing a policy:
 
1. Bump `version` in the policy's `Policy.yaml`.
2. Update the policy's `CHANGELOG.md` and `README.md`.
3. Regenerate [`POLICIES.md`](./POLICIES.md) and commit it.
4. Make sure CI validation passes.
---
 
## Contributing
 
Contributions are welcome — a new policy is often only a `Policy.yaml` and a
manifest away. See [CONTRIBUTING.adoc](./CONTRIBUTING.adoc) for the full
guidelines.
 
Before opening a pull request:
 
- Open an issue first for anything non-trivial.
- Bump `Policy.yaml` `version` if behaviour changes.
- Update the policy README, changelog, and example values.
- Make sure CI passes.
New policy directories should follow the naming convention
`<category>/<subject>[/<action>]`, matching the existing `autodiscovery/*`
policies.
 
By participating you agree to the [Code of Conduct](./CODE_OF_CONDUCT.md).
 
---
 
## FAQ
 
**Why a monorepo?**
It keeps discovery, CI, and publishing in one place. Splitting into multiple
repositories remains an option if the catalogue outgrows it.
 
**Can I publish my own policies?**
Yes — to any OCI registry you control. See
[share and reuse](https://www.updatecli.io/docs/core/shareandreuse/).
 
**A policy proposed a change I didn't expect.**
Run `updatecli manifest show <policy>` to see exactly what it does, and open an
issue with the output. Always use `diff` before `apply` on a new policy.
 
---
 
## Getting help
 
- 💬 [Matrix chat](https://matrix.to/#/#Updatecli_community:gitter.im)
- 🐛 [Issues](https://github.com/updatecli/policies/issues)
- 📖 [Updatecli documentation](https://www.updatecli.io/docs/prologue/introduction/)
- 📦 [Published packages](https://github.com/orgs/updatecli/packages?repo_name=policies)
## Thanks to all the contributors ❤️
 
<a href="https://github.com/updatecli/policies/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=updatecli/policies" alt="Contributors">
</a>

## License
 
[Apache-2.0](./LICENSE)
