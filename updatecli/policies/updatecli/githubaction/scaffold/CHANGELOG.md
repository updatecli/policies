# CHANGELOG

## 0.2.0

* Add `gha.steps` and `gha.<workflow>.steps`: an escape hatch for tooling this policy does
  not curate. Entries are GitHub Action steps, injected between "Setup updatecli" and
  "Run updatecli" and passed through verbatim. The policy does not pin, resolve or refresh
  them -- that stays the caller's responsibility. GitHub Action expressions need no
  escaping; YAML comments on a step are not preserved.
* `gha.golang` and `gha.npm` are unchanged, and remain the curated path: pinned to a
  commit digest, tag kept as a trailing comment, refreshed on every run.
* Generated workflows are byte-identical to 0.1.1 for every existing configuration, so
  upgrading opens no pull request on its own.

## 0.1.1

* Disable NPM caching
* Disable Golang caching

## 0.1.0

* Initial release
