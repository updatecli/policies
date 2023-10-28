#!/usr/bin/env bash
set -euo pipefail

# Ensure we work from the Updatecli directory
# This is even more important as we use the policy path to generate the policy reference
pushd updatecli

: "${POLICIES_ROOT_DIR:=policies}"
: "${POLICY_ERROR:=false}"

: "${GITHUB_REGISTRY:=}"

POLICIES=$(find "$POLICIES_ROOT_DIR" -name "Policy.yaml")

# release publish an Updatecli policy version to the registry
function release(){
  local POLICY_ROOT_DIR="$1"
  
  updatecli manifest push \
    --config updatecli.d \
    --values values.yaml \
    --policy Policy.yaml \
    --tag "ghcr.io/updatecli/policies/$POLICY_ROOT_DIR" \
    "$POLICY_ROOT_DIR"
}

function runUpdatecliDiff(){
  local POLICY_ROOT_DIR="$1"
  
  updatecli diff \
    --config "$POLICY_ROOT_DIR/updatecli.d" \
    --values "$POLICY_ROOT_DIR/values.yaml" \
    --experimental 
}

function validateRequiredFile(){
  local POLICY_ROOT_DIR="$1"
  local POLICY_VALUES="$POLICY_ROOT_DIR/values.yaml"
  local POLICY_README="$POLICY_ROOT_DIR/README.md"
  local POLICY_CHANGELOG="$POLICY_ROOT_DIR/CHANGELOG.md"

  echo ""
  echo "$POLICY_ROOT_DIR"
  echo ""

  echo "validating policy..."


  # Checking for files
  for POLICY_FILE in "$POLICY_VALUES" "$POLICY_CHANGELOG" "$POLICY_README"
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

}

function main(){

  PARAM="$1"

  GLOBAL_ERROR=0

  for POLICY in $POLICIES
  do 
    echo ""
  
    POLICY_ROOT_DIR=$(dirname "$POLICY")
    POLICY_ERROR=false
      validateRequiredFile "$POLICY_ROOT_DIR"

    if [[ "$POLICY_ERROR" = "false" ]]; then
      echo "  => all is good for policy: $POLICY"
      echo ""

      if [[ "$PARAM" == "--publish" ]]; then
        release "$POLICY_ROOT_DIR"
      fi
      echo "___"
    else 
      echo ""
      echo "  => validation test not passing"
      echo ""
      echo "---"

      GLOBAL_ERROR=1
    fi

  
  done

    exit "$GLOBAL_ERROR"
}

main "${1:-}"
