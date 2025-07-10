# Changelog

## 0.12.0

! Require Updatecli 0.103.0

* Add policy support for gitlab, gitea, stash and bitbucket
* By default disable scm configuration

## 0.11.0

* Configure Pull Request GitHub labels using `labels`.

## 0.10.0

* Allow to opt out `scm.email`.

## 0.9.0

* Allow to set commit with GitHub GraphQL API using `scm.commitusingapi`

## 0.8.0

* By default, undefined pipelineid

## 0.7.0

* Allow to override pipeline name

## 0.6.0

* Rename `npm.spec` to `spec`
* By default don't set groupby
* Cleaning test setting

## 0.5.0

* Swap default order for scm configuration to use environment variable if nothing else is defined

## 0.4.0

* Specify default autodiscovery groupby value

## 0.3.0

* update default pipelineid value to use _ instead /
* update pipeline name

## 0.2.0

* remove github branch detection

## 0.1.0

* init policy

