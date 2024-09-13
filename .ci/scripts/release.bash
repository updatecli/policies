#!/usr/bin/env bash
set -euo pipefail

# Ensure we work from the Updatecli directory
# This is even more important as we use the policy path to generate the policy reference
pushd updatecli

: "${POLICIES_ROOT_DIR:=policies}"
: "${POLICY_ERROR:=false}"
: "${OCI_REPOSITORY:=ghcr.io/updatecli/policies}"

: "${GITHUB_REGISTRY:=}"

POLICIES=$(find "$POLICIES_ROOT_DIR" -name "Policy.yaml")

# release publish an Updatecli policy version to the registry
function release(){
  local POLICY_ROOT_DIR="$1"
  # Trim policy path with root directory path
  local POLICY_DIR="${1#"$POLICIES_ROOT_DIR/"}"

  updatecli manifest push \
    --config updatecli.d \
    --values values.yaml \
    --policy Policy.yaml \
    --tag "$OCI_REPOSITORY/$POLICY_DIR" \
    "$POLICY_ROOT_DIR"
}

function runUpdatecliDiff(){
  local POLICY_ROOT_DIR=""
  POLICY_ROOT_DIR="$1"

  updatecli diff \
    --config "$POLICY_ROOT_DIR/updatecli.d" \
    --values "$POLICY_ROOT_DIR/values.yaml" \
    --values "$POLICY_ROOT_DIR/testdata/values.yaml"
}

function validateRequiredFile(){
  local POLICY_ROOT_DIR="$1"
  local POLICY_VALUES="$POLICY_ROOT_DIR/values.yaml"
  local POLICY_README="$POLICY_ROOT_DIR/README.md"
  local POLICY_METADATA="$POLICY_ROOT_DIR/Policy.yaml"
  local POLICY_CHANGELOG="$POLICY_ROOT_DIR/CHANGELOG.md"

  echo "* validating policy $POLICY_ROOT_DIR"


  # Checking for files
  for POLICY_FILE in "$POLICY_VALUES" "$POLICY_CHANGELOG" "$POLICY_README" "$POLICY_METADATA"
  do
    if [[ ! -f "$POLICY_FILE" ]]; then

      POLICY_ERROR=true
      echo "  * file '$POLICY_FILE' missing for policy $POLICY_ROOT_DIR"
      true
    fi
  done

  local POLICY_MANIFEST="$POLICY_ROOT_DIR/updatecli.d"
  # Checking for directories
  if [[ ! -d "$POLICY_MANIFEST" ]]; then

    POLICY_ERROR=true
    echo "  * directory '$POLICY_MANIFEST' missing for policy $POLICY_ROOT_DIR"
    true
  fi

  ## Testing that Policy.yaml contains the required information
  local sourceInformation=""
  sourceInformation=$(grep "source:" "$POLICY_METADATA" )
  sourceInformation=${sourceInformation#"source: "}
  local expectedSourceInformation="\"https://github.com/updatecli/policies/tree/main/updatecli/$POLICY_ROOT_DIR/\""
  if [[ ! $sourceInformation == "$expectedSourceInformation" ]]; then
    POLICY_ERROR=true
    echo "  * policy $POLICY_ROOT_DIR missing the right source information in Policy.yaml"
    echo "     expected: $expectedSourceInformation"
    echo "     got:      $sourceInformation"
  fi

  local documentationInformation=""
  documentationInformation=$(grep "documentation:" "$POLICY_METADATA")
  documentationInformation=${documentationInformation#"documentation: "}
  local expectedDocumentationInformation="\"https://github.com/updatecli/policies/tree/main/updatecli/$POLICY_ROOT_DIR/README.md\""
  if [[ ! $documentationInformation == "$expectedDocumentationInformation" ]]; then
    POLICY_ERROR=true
    echo "  * policy $POLICY_ROOT_DIR missing the right documentation information in Policy.yaml"
    echo "     expected: $expectedDocumentationInformation"
    echo "     got:      $documentationInformation"
  fi

  # Testing url annotation is defined
  local urlInformation=""
  urlInformation=$( grep "url:" "$POLICY_METADATA")
  urlInformation=${urlInformation#"url: "}
  local expectedUrlInformation="\"https://github.com/updatecli/policies/\""
  if [[ ! $urlInformation == "$expectedUrlInformation" ]]; then
    POLICY_ERROR=true
    echo "  * policy $POLICY_ROOT_DIR missing the right url information in Policy.yaml"
    echo "     expected: $expectedUrlInformation"
    echo "     got:      $urlInformation"
  fi

  # Testing version annotation is defined
  local versionInformation=""
  versionInformation=$( grep "version:" "$POLICY_METADATA")
  versionInformation=${versionInformation#"version: "}
  if [[ $versionInformation == "" ]]; then
    POLICY_ERROR=true
    echo "  * policy $POLICY_ROOT_DIR missing a version information in Policy.yaml"
  fi

  # Testing that the latest version has a changelog entry
  local versionChangelogEntry=""
  versionChangelogEntry=$( grep " $versionInformation" "$POLICY_CHANGELOG")
  if [[ $versionChangelogEntry == "" ]]; then
    POLICY_ERROR=true
    echo "  * Changelog missing a version entry such as '## $versionInformation' in $POLICY_CHANGELOG"
  fi

  # Testing that the latest changelog version is used in the Policy.yaml
  latestVersionChangelogEntry=$( grep -r '## ' -m 1 "$POLICY_CHANGELOG")
  latestVersionChangelogEntry=${latestVersionChangelogEntry#"## "}
  if [[ "$latestVersionChangelogEntry" != "$versionInformation" ]]; then
    POLICY_ERROR=true
    echo "  * Latest Changelog version isn't the one used in Policy.yaml"
    echo "      '## $latestVersionChangelogEntry' in $POLICY_CHANGELOG"
    echo "      '## $versionInformation' in $POLICY_METADATA"
  fi
}

function main(){

  PARAM="$1"

  GLOBAL_ERROR=0

  for POLICY in $POLICIES
  do
    echo ""

    POLICY_ROOT_DIR=$(dirname "$POLICY")
    POLICY_ERROR=false

    if [[ "$PARAM" == "--e2e-test" ]]; then
      runUpdatecliDiff "$POLICY_ROOT_DIR"
    fi

    if [[ "$PARAM" == "--unit-test" ||  "$PARAM" == "" ]]; then
      validateRequiredFile "$POLICY_ROOT_DIR"
    fi

    if [[ "$POLICY_ERROR" = "false" ]]; then
      echo "  => all is good"

      if [[ "$PARAM" == "--publish" ]]; then
        release "$POLICY_ROOT_DIR"
      fi

    else
      echo ""
      echo "  => validation test not passing"

      GLOBAL_ERROR=1
    fi

  done

    exit "$GLOBAL_ERROR"
}

main "${1:-}"

