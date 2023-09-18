#!/usr/bin/env bash
. scripts/functions.sh
TOKEN=$1

#if one of the modules is updated, increase the project version number in the pom.xml as a minor release
if grep -q "updating" commit-message.txt; then
  CURRENT_VERSION=$(yq '.project.version' pom.xml)
  NEW_VERSION=$(echo "$CURRENT_VERSION" | (
    IFS=".$IFS"
    read major minor revision && echo "$major".$((minor + 1)).0
  ))
  echo "Updating project version to $NEW_VERSION"
  printf "Blopup-openmrs-distribution project version to %s" "$NEW_VERSION" >>commit-message.txt
  yq -i '.project.version = "'"$NEW_VERSION"'"' pom.xml

  SHA=$(get_file_sha pom.xml)
  encode_file_and_save_request_data_to_file_with_sha pom.xml "$SHA"
  push_file_to_repo pom.xml

  COMMIT_SHA=$(jq -r '.commit.sha' response.json)
  echo '{"tag": "'"$NEW_VERSION"'", "message": "'"$COMMIT_MESSAGE"'", "object": "'"$COMMIT_SHA"'", "type": "commit"}' >data.json
  create_tag_reference_for_commit "$NEW_VERSION" "$COMMIT_SHA"
fi
