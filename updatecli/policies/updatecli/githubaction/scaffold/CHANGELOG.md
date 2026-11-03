# CHANGELOG

## 0.3.0

* When `gha.udash.enabled` is true, add a `refresh` job to the update workflow that runs `updatecli compose diff` across all pipelines once the matrix jobs finish, so Udash is notified of merged or closed pull requests

## 0.2.0

* Add the `merge.strategy` and `merge.after` values, replacing the deprecated `automerge` field

## 0.1.1

* Disable NPM caching
* Disable Golang caching

## 0.1.0

* Initial release
