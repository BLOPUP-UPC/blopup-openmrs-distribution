#!/usr/bin/env bash

TOKEN=$1

# find and delete files in docker/web/modules starting with blopup.notification-*
find docker/web/modules -name 'blopup.notification-*' -delete

# download blopup-notification-module latest release asset ID and name from github api
RELEASE=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/BLOPUP-UPC/blopup-notification-module/releases/latest)

ASSET_ID=$(echo "$RELEASE" | jq -r '.assets[0].id')
ASSET_NAME=$(echo "$RELEASE" | jq -r '.assets[0].name')

#get the asset from github api passing the asset ID and save it in the modules folder
curl -sL \
  -H "Accept: application/octet-stream" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/BLOPUP-UPC/blopup-notification-module/releases/assets/"$ASSET_ID" \
  > docker/web/modules/"$ASSET_NAME"

#encode the asset content in base64 and save to file
ENCODED_CONTENT=$(base64 -i docker/web/modules/"$ASSET_NAME")
echo '{"message": "updating modules - '"$ASSET_NAME"'", "content":"'"$ENCODED_CONTENT"'"}' > data.json

#push the new module to the repository
curl -sL \
  -X PUT \
 -H "Accept: application/vnd.github+json" \
 -H "Authorization: Bearer $TOKEN" \
 -H "X-GitHub-Api-Version: 2022-11-28" \
 -d @data.json \
  https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/docker/web/modules/"$ASSET_NAME" \
  > response.json

#check if response.json contains string Invalid request
if grep -q 'Invalid request' response.json; then
  echo "Already using latest module version - $ASSET_NAME"
fi

#check if response.json contains asset name string
if grep -q "$ASSET_NAME" response.json; then
  echo "Module updated - $ASSET_NAME"
fi

#delete response.json and data.json
rm response.json  data.json
