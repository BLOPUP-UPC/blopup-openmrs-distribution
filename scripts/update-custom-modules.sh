#!/usr/bin/env bash

TOKEN=$1
touch result.txt
touch commit-message.txt

for module_repo_and_name in \
"notification blopup.notification" \
"file-upload blopup.fileupload.module" \

do
    set -- $module_repo_and_name # split the string into positional parameters

# find and delete files in docker/web/modules starting with the module name
find docker/web/modules -name "$2-*" -delete

# download the module's latest release asset ID and name from github api
RELEASE=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/BLOPUP-UPC/"$1"/releases/latest)

ASSET_ID=$(echo "$RELEASE" | jq -r '.assets[0].id')
ASSET_NAME=$(echo "$RELEASE" | jq -r '.assets[0].name')

#get the asset from github api passing the asset ID and save it in the modules folder
curl -sL \
  -H "Accept: application/octet-stream" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/BLOPUP-UPC/"blopup-$1-module"/releases/assets/"$ASSET_ID" \
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
  echo "Module updated - $ASSET_NAME" >> result.txt

  CURRENT_VERSION=$(yq ".project.properties.$2Version" pom.xml)
  NEW_VERSION=$(echo "$ASSET_NAME" | (IFS="-.$IFS" ; read module_name version && echo "$version"))
  echo "Updating $2 module version from $CURRENT_VERSION to $NEW_VERSION"
  echo "Updating $2 module version from $CURRENT_VERSION to $NEW_VERSION \n" >> commit-message.txt
  yq -i ".project.properties.$2Version = $NEW_VERSION" pom.xml
fi

done