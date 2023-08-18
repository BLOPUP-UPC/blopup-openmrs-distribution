TOKEN=$1

#get latest reference application
curl -s https://sourceforge.net/projects/openmrs/files/releases/ > response.html
grep -o "OpenMRS_Reference_Application_[0-9]*\.[0-9]*\.[0-9]*" response.html > ref_app_versions.txt
LATEST_REFERENCE_APPLICATION_VERSION=$(head -n 1 ref_app_versions.txt | cut -d '_' -f 4)

#compare with current version and download newer version if available
CURRENT_REFERENCE_APPLICATION_VERSION=$(yq '.project.properties.referenceapplicationVersion' pom.xml)
if [ "$LATEST_REFERENCE_APPLICATION_VERSION" == "$CURRENT_REFERENCE_APPLICATION_VERSION" ]; then
  echo "Already using latest reference application version - $LATEST_REFERENCE_APPLICATION_VERSION"
else
  echo "Newer reference application version available"
  echo "Updating reference application version to $LATEST_REFERENCE_APPLICATION_VERSION"
  echo "Downloading modules"
  #download and replace modules
  wget -q https://sourceforge.net/projects/openmrs/files/releases/OpenMRS_Reference_Application_"$LATEST_REFERENCE_APPLICATION_VERSION"/referenceapplication-addons-$LATEST_REFERENCE_APPLICATION_VERSION.zip/ -O file.zip
  echo "Unzipping files"
  unzip -q file

  #updating owa file
  echo "Updating owa file"
  rm -r docker/web/owa
  mv referenceapplication*/owa docker/web/

#replacing modules with newer version available
ls referenceapplication*/modules > referenceapplication_modules.txt
echo "Replacing modules with newer version available"
while IFS=$'\n' read -r module; do
  module_name=$(echo "$module" | cut -d '-' -f 1)
  module_to_update=$(find docker/web/modules -name "$module_name-*")
if [ -z "$module_to_update" ]; then
    echo "Latest version already installed- $module_name"
  else
    echo "Module update found - $module_name"

#get file sha
curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/"$module_to_update" > response.json

SHA=$(jq -r '.sha' response.json)

curl -sL \
  -X DELETE \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/"$module_to_update" \
  -d '{"message":"removing outdated module '"$module_to_update"'", "sha":"'"$SHA"'"}' > response.json
  fi
done < referenceapplication_modules.txt

echo "Committing updated modules"
#encode the asset content in base64, create request data and save to file
ENCODED_CONTENT=$(base64 -i referenceapplication*/modules/"$module"*)
echo '{"message": "updating '"$module_name"' to match reference application version '"$LATEST_REFERENCE_APPLICATION_VERSION'"'", "content":"'"$ENCODED_CONTENT"'"}' > data.json
#push the new modules to the repository
curl -sL \
  -X PUT \
 -H "Accept: application/vnd.github+json" \
 -H "Authorization: Bearer $TOKEN" \
 -H "X-GitHub-Api-Version: 2022-11-28" \
 -d @data.json \
  https://api.github.com/repos/BLOPUP-UPC/blopup-openmrs-distribution/contents/docker/web/modules/"$module" \
  > response.json

if grep -q "modules" response.json; then
echo "Updating reference application version to $LATEST_REFERENCE_APPLICATION_VERSION"
yq -i '.project.properties.referenceapplicationVersion = "'"$LATEST_REFERENCE_APPLICATION_VERSION"'"' pom.xml
else
  echo "Error committing the changes"
fi

rm file.zip
rm -r referenceapplication*
fi

#clean up
rm ref_app_versions.txt response.html

sh scripts/update-version-numbers.sh "$TOKEN"