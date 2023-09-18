get_file_sha() {
  curl -sL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/docker/web/modules/"$1" >response.json

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
    -d '{"message":"removing outdated module", "sha":"'"$2"'"}'
}

push_new_file_to_repo() {
  curl -sL \
    -X PUT \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -d @data.json \
    https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/docker/web/modules/"$1" \
    >response.json
}

encode_file_and_save_request_data_to_file() {
  ENCODED_CONTENT=$(base64 -i docker/web/modules/"$1")
  echo '{"message": "updating modules - '"$1"'", "content":"'"$ENCODED_CONTENT"'"}' >data.json
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
