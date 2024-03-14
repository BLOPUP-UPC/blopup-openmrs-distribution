#!/usr/bin/env bash
source scripts/functions.sh
TOKEN=$1

echo "file to check if any new version should be created">confirm-commit.txt
echo "Updating custom module created by BLOPUP"

  #find current module version
  CURRENT_VERSION=$(find docker/web/modules -name "blopup.openmrs.module-*" | cut -d '/' -f 4)

  LATEST_RELEASE=$(get_latest_release_for_repo)
  ASSET_ID=$(echo "$LATEST_RELEASE" | jq -r '.assets[0].id')
  ASSET_NAME=$(echo "$LATEST_RELEASE" | jq -r '.assets[0].name')

  #compare latest module version with current version
  if [ "$CURRENT_VERSION" = "$ASSET_NAME" ]; then
    echo "Already using latest module version - $ASSET_NAME"
  else
    echo "Updating module - $ASSET_NAME"
    download_asset_to_local_directory "$ASSET_ID" "$ASSET_NAME"
    encode_file_and_save_request_data_to_file docker/web/modules/"$ASSET_NAME"
    push_file_to_repo docker/web/modules/"$ASSET_NAME"

    NEW_VERSION=$(echo "$ASSET_NAME" | cut -d '-' -f 2)
    NEW_VERSION=$(echo "$NEW_VERSION" | cut -d '.' -f 1,2,3)
    update_module_version_in_pom "$NEW_VERSION"

    echo "Deleting outdated module - $CURRENT_VERSION"
    OUTDATED_MODULE_SHA=$(get_file_sha docker/web/modules/"$CURRENT_VERSION")
    delete_file_with_sha "$CURRENT_VERSION" "$OUTDATED_MODULE_SHA"

    printf "commit" >>confirm-commit.txt
  fi

sh scripts/get-latest-reference-application.sh "$TOKEN"
