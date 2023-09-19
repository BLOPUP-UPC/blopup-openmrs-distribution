#######################################
# Get the sha of a file in github by its path.
# Globals:
#   TOKEN
# Arguments:
#   File to fetch, a path.
# Returns:
#   The SHA of the file if exists.
#######################################
get_file_sha() {
  curl -sL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/"$1" >response.json

  SHA=$(jq -r '.sha' response.json)

  echo "$SHA"
}

#######################################
# Delete a file in github by its sha.
# Globals:
#   TOKEN
# Arguments:
#   File to delete, a path.
#   SHA of the file to delete.
#######################################
delete_file_with_sha() {
  curl -sL \
    -X DELETE \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/docker/web/modules/"$1" \
    -d '{"message":"removing outdated module - '"$1"'", "sha":"'"$2"'"}' > delete.json
}

#######################################
# Push a file to github.
# Globals:
#   TOKEN
# Arguments:
#   File to push, a path.
#######################################
push_file_to_repo() {
  curl -sL \
    -X PUT \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -d @data.json \
    https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/"$1" \
    >response.json
}

#######################################
# Base64 encode a file and save data to data.json file.
# Arguments:
#   File to encode, a path.
#######################################
encode_file_and_save_request_data_to_file() {
  ENCODED_CONTENT=$(base64 -i "$1")
  echo '{"message": "updating '"$1"'", "content":"'"$ENCODED_CONTENT"'"}' >data.json
}

#######################################
# Base64 encode a file and request body to data.json file.
# Arguments:
#   File to encode, a path.
#######################################
encode_file_and_save_request_data_to_file_with_sha() {
  ENCODED_CONTENT=$(base64 -i "$1")
  echo '{"message": "updating '"$1"'", "content":"'"$ENCODED_CONTENT"'", "sha": "'"$2"'"}' >data.json
}

#######################################
# Get the latest release for a module repo.
# Globals:
#   TOKEN
# Arguments:
#   Module name.
# Returns:
#   Write the latest release for the repo to stdout.
#######################################
get_latest_release_for_repo() {
  echo "$(curl -sL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/BLOPUP-UPC/blopup-"$1"-module/releases/latest)"
}

#######################################
# Download an asset from a release.
# Globals:
#   TOKEN
# Arguments:
#   Module name.
#   Asset name/version.
#   Local file name.
#
# Returns:
#   Write the asset to the local file.
#######################################
download_asset_to_local_directory() {
  curl -sL \
    -H "Accept: application/octet-stream" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/BLOPUP-UPC/blopup-"$1"-module/releases/assets/"$2" \
    >"docker/web/modules/$3"
}

#######################################
# Update the version of a module in the pom.xml file.
# Arguments:
#   Module name.
#   New version.
#######################################
update_module_version_in_pom() {
  yq -i '.project.properties.'"$1"'Version = "'"$2"'"' pom.xml
}

#######################################
# Download reference application versions from sourceforge.
# Returns:
#   Write the versions to ref_app_versions.txt file.
#######################################
save_reference_application_versions_to_file() {
  curl -s https://sourceforge.net/projects/openmrs/files/releases/ >response.html
  grep -o "OpenMRS_Reference_Application_[0-9]*\.[0-9]*\.[0-9]*" response.html >ref_app_versions.txt
}

#######################################
# Download and unzip reference application modules.
# Arguments:
#   Reference application version.
# Returns:
#   Write the modules a local directory.
#######################################
download_and_unzip_reference_application_modules() {
  wget -q https://sourceforge.net/projects/openmrs/files/releases/OpenMRS_Reference_Application_"$1"/referenceapplication-addons-$1.zip/ -O file.zip
  echo "Unzipping files"
  unzip -q file
}

#######################################
# Create a tag reference for a commit.
# Globals:
#   TOKEN
# Arguments:
#   Tag name.
#   Commit SHA.
#######################################
create_tag_reference_for_commit() {
    echo '{"ref": "refs/tags/v'"$1"'", "sha": "'"$2"'"}' >data.json
    curl -sL \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/git/refs \
      -d @data.json >response.json
}