get_file_sha() {
  curl -sL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/"$1" >response.json

  SHA=$(jq -r '.sha' response.json)

  echo "$SHA"
}

delete_file_with_sha() {
  curl -sL \
    -X DELETE \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/docker/web/modules/"$1" \
    -d '{"message":"removing outdated module - '"$1"'", "sha":"'"$2"'"}' > delete.json
}

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

encode_file_and_save_request_data_to_file() {
  ENCODED_CONTENT=$(base64 -i "$1")
  echo '{"message": "updating '"$1"'", "content":"'"$ENCODED_CONTENT"'"}' >data.json
}

encode_file_and_save_request_data_to_file_with_sha() {
  ENCODED_CONTENT=$(base64 -i "$1")
  echo '{"message": "updating '"$1"'", "content":"'"$ENCODED_CONTENT"'", "sha": "'"$2"'"}' >data.json
}

get_latest_release_for_repo() {
  echo "$(curl -sL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/BLOPUP-UPC/blopup-"$1"-module/releases/latest)"
}

download_asset_to_local_directory() {
  curl -sL \
    -H "Accept: application/octet-stream" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/BLOPUP-UPC/blopup-"$1"-module/releases/assets/"$2" \
    >"docker/web/modules/$3"
}

update_module_version_in_pom() {
  yq -i '.project.properties.'"$1"'Version = "'"$2"'"' pom.xml
}

save_reference_application_versions_to_file() {
  curl -s https://sourceforge.net/projects/openmrs/files/releases/ >response.html
  grep -o "OpenMRS_Reference_Application_[0-9]*\.[0-9]*\.[0-9]*" response.html >ref_app_versions.txt
}

download_and_unzip_reference_application_modules() {
  wget -q https://sourceforge.net/projects/openmrs/files/releases/OpenMRS_Reference_Application_"$1"/referenceapplication-addons-$1.zip/ -O file.zip
  echo "Unzipping files"
  unzip -q file
}

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