#if one of the modules is updated, increase the project version number in the pom.xml as a minor release
if grep -q "Module updated" result.txt; then
CURRENT_VERSION=$(yq '.project.version' pom.xml)
NEW_VERSION=$(echo "$CURRENT_VERSION" | (IFS=".$IFS" ; read major minor revision && echo "$major".$((minor + 1)).0))
echo "Updating project version from $CURRENT_VERSION to $NEW_VERSION"
echo "Updating project version from $CURRENT_VERSION to $NEW_VERSION" >> commit-message.txt
yq -i '.project.version = "'"$NEW_VERSION"'"' pom.xml
fi

#encode the pom file in base64 and save to file
ENCODED_CONTENT=$(base64 -i pom.xml)
echo '{"message": "'commit-message.txt'", "content":"'"$ENCODED_CONTENT"'"}' > pom.json

# tag commit with project version

#push updated pom file to the repo
#needs sha for the commit to update in order to update existing file
curl -sL \
  -X PUT \
 -H "Accept: application/vnd.github+json" \
 -H "Authorization: Bearer $TOKEN" \
 -H "X-GitHub-Api-Version: 2022-11-28" \
 -d @pom.json \
  https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/pom.xml

#delete all temp files created for this operation
rm response.json  data.json result.txt commit-message.txt pom.json