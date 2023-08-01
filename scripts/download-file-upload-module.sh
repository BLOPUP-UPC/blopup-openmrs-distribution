#!/usr/bin/env bash

TOKEN=$1
REPOSITORY=$2

# find and delete files in docker/web/modules starting with blopup.fileupload.module-*
find docker/web/modules -name 'blopup.fileupload.module-*' -delete

# download blopup-file-upload-module latest release asset ID and name from github api
RELEASE=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/BLOPUP-UPC/blopup-file-upload-module/releases/latest)

ASSET_ID=$(echo "$RELEASE" | jq -r '.assets[0].id')
ASSET_NAME=$(echo "$RELEASE" | jq -r '.assets[0].name')

#get the asset from github api passing the asset ID and save it in the modules folder
curl -sL \
  -H "Accept: application/octet-stream" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/BLOPUP-UPC/blopup-file-upload-module/releases/assets/$ASSET_ID \
  > "$ASSET_NAME"

#commit and push the new module to the repository
FILE=$(base64 -i "$ASSET_NAME")

curl -sL \
 -X PUT \
 -H "Accept: application/vnd.github+json" \
 -H "Authorization: Bearer $TOKEN" \
 -H "X-GitHub-Api-Version: 2022-11-28" \
 https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/docker/web/modules/"$ASSET_NAME" \
 -d "{'message':'updating modules: $ASSET_NAME','committer':{'name':'Github Actions','email':''},'content':'$FILE'}"

#next steps:
# - do the same for the notification module
