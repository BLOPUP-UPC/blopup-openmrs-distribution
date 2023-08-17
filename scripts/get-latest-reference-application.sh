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
  wget -q https://sourceforge.net/projects/openmrs/files/releases/OpenMRS_Reference_Application_"$LATEST_REFERENCE_APPLICATION_VERSION"/referenceapplication-addons-$LATEST_REFERENCE_APPLICATION_VERSION.zip/ -O docker/file.zip
  echo "Unzipping files"
  unzip -q docker/file
  rsync -a referenceapplication*/modules docker/web
  rm docker/web/owa
  mv referenceapplication*/owa docker/web/owa

while IFS=$'\n' read -r module; do
  find . -name "docker/web/modules/$module*" -delete
done < $(ls referenceapplication*/modules)
  #commit the changes to the modules via github api
  echo "Committing changes to github"
fi




#encode the asset content in base64, create request data and save to file
ENCODED_CONTENT=$(base64 -i pom.xml)
echo '{"message": "updating reference application version to '"$LATEST_REFERENCE_APPLICATION_VERSION"'", "content":"'"$ENCODED_CONTENT"'"}' > data.json


#clean up
rm ref_app_versions.txt response.html file.zip -r referenceapplication*