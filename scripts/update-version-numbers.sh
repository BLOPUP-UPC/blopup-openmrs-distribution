TOKEN=$1

#if one of the modules is updated, increase the project version number in the pom.xml as a minor release
if grep -q "module" commit-message.txt; then
CURRENT_VERSION=$(yq '.project.version' pom.xml)
NEW_VERSION=$(echo "$CURRENT_VERSION" | (IFS=".$IFS" ; read major minor revision && echo "$major".$((minor + 1)).0))
echo "Updating project version to $NEW_VERSION"
printf "Blopup-openmrs-distribution project version to %s" "$NEW_VERSION" >> commit-message.txt
yq -i '.project.version = "'"$NEW_VERSION"'"' pom.xml

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
echo '{"message": "'"$COMMIT_MESSAGE"'", "content":"'"$ENCODED_CONTENT"'", "sha": "'"$SHA"'"}' > data.json

#push updated pom file to the repo
curl -sL \
  -X PUT \
 -H "Accept: application/vnd.github+json" \
 -H "Authorization: Bearer $TOKEN" \
 -H "X-GitHub-Api-Version: 2022-11-28" \
 -d @data.json \
  https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/pom.xml > response.json

#get commit sha from response
COMMIT_SHA=$(jq -r '.commit.sha' response.json)

#create a tag for the commit
echo '{"tag": "'"$NEW_VERSION"'", "message": "'"$COMMIT_MESSAGE"'", "object": "'"$COMMIT_SHA"'", "type": "commit"}' > data.json

#create tag reference for the commit
echo '{"ref": "refs/tags/v'"$NEW_VERSION"'", "sha": "'"$COMMIT_SHA"'"}' > data.json
curl -sL \
       -X POST \
       -H "Accept: application/vnd.github+json" \
       -H "Authorization: Bearer $TOKEN" \
       -H "X-GitHub-Api-Version: 2022-11-28" \
       https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/git/refs \
       -d @data.json > response.json
fi

#delete all temp files created for this operation
rm data.json commit-message.txt response.json
