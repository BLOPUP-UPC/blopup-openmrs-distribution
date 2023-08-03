TOKEN=$1

#if one of the modules is updated, increase the project version number in the pom.xml as a minor release
if grep -q "module" commit-message.txt; then
CURRENT_VERSION=$(yq '.project.version' pom.xml)
NEW_VERSION=$(echo "$CURRENT_VERSION" | (IFS=".$IFS" ; read major minor revision && echo "$major".$((minor + 1)).0))
echo "Updating project version from $CURRENT_VERSION to $NEW_VERSION"
echo "Updating blopup-openmrs-distribution project version from $CURRENT_VERSION to $NEW_VERSION" >> commit-message.txt
yq -i '.project.version = "'"$NEW_VERSION"'"' pom.xml
fi

#get pom.xml sha
curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/pom.xml > response.json

SHA=$(jq -r '.sha' response.json)

#encode the pom file in base64 and save request body to file
ENCODED_CONTENT=$(base64 -i pom.xml)
COMMIT_MESSAGE=$(cat commit-message.txt)
echo '{"message": "'"$COMMIT_MESSAGE"'", "content":"'"$ENCODED_CONTENT"'", "sha": "'"$SHA"'"}' > pom.json

# tag commit with project version

#push updated pom file to the repo
#needs sha for the commit to update in order to update existing file
curl -sL \
  -X PUT \
 -H "Accept: application/vnd.github+json" \
 -H "Authorization: Bearer $TOKEN" \
 -H "X-GitHub-Api-Version: 2022-11-28" \
 -d @pom.json \
  https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/pom.xml > response.json

#delete all temp files created for this operation
rm response.json  data.json commit-message.txt pom.json