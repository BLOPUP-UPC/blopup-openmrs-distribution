#!/usr/bin/env bash

TOKEN=$1
echo "Updating versions: " > commit-message.txt

#the name of the repo with the format `blopup-<name>-module`
for name in \
"notification" \
"file-upload"
do
#find current module version
CURRENT_MODULE=$(find docker/web/modules -name "blopup.$MODULE_NAME-*")

# download the module's latest release asset ID and name from github api
RELEASE=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/BLOPUP-UPC/blopup-"$name"-module/releases/latest)

ASSET_ID=$(echo "$RELEASE" | jq -r '.assets[0].id')
ASSET_NAME=$(echo "$RELEASE" | jq -r '.assets[0].name')
MODULE_NAME=$(echo "$ASSET_NAME" | cut -d '-' -f 1)
MODULE_NAME=$(echo "$MODULE_NAME" | cut -d '.' -f 2)

#get the asset from github api passing the asset ID and save it in the modules folder
curl -sL \
  -H "Accept: application/octet-stream" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/BLOPUP-UPC/blopup-"$name"-module/releases/assets/"$ASSET_ID" \
  > docker/web/modules/"$ASSET_NAME"

#encode the asset content in base64, create request data and save to file
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

#check if response.json contains asset name string and update module version number in pom.xml
if grep -q "$ASSET_NAME" response.json; then
  echo "Module updated - $ASSET_NAME"

#delete outdated module from the repository
#get file sha
curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/"$CURRENT_MODULE" > response.json

SHA=$(jq -r '.sha' response.json)

curl -L \
  -X DELETE \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/"$CURRENT_MODULE" \
  -d '{"message":"removing outdated module", "sha":"'"$SHA"'"}'

NEW_VERSION=$(echo "$ASSET_NAME" | cut -d '-' -f 2)
NEW_VERSION=$(echo "$NEW_VERSION" | cut -d '.' -f 1,2,3)

echo "Updating $MODULE_NAME module version to $NEW_VERSION"
printf "%s module to version %s." "$MODULE_NAME" "$NEW_VERSION" >> commit-message.txt
yq -i '.project.properties.'"$MODULE_NAME"'Version = "'"$NEW_VERSION"'"' pom.xml
fi
done

sh scripts/get-latest-reference-application.sh "$TOKEN"