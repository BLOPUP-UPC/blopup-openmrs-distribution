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

#removing modules with newer version available
ls referenceapplication*/modules > referenceapplication_modules.txt
echo "Replacing modules with newer version available"
while IFS=$'\n' read -r module; do
  module_name=$(echo "$module" | cut -d '-' -f 1)
  find docker/web/modules -name "$module_name-*" -exec rm {} \;
  echo "Found newer version for $module_name"
done < referenceapplication_modules.txt

#syncing
echo "Syncing modules"
rsync -a referenceapplication*/modules/ docker/web/modules/

#update referenceapplicationVersion in pom.xml
echo "Updating reference application version to $LATEST_REFERENCE_APPLICATION_VERSION"
yq -i '.project.properties.referenceapplicationVersion = "'"$LATEST_REFERENCE_APPLICATION_VERSION"'"' pom.xml

rm file.zip
rm -r referenceapplication*
fi

#clean up
rm ref_app_versions.txt response.html
