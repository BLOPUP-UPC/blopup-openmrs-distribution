#!/usr/bin/env bash
. scripts/functions.sh
TOKEN=$1

save_reference_application_versions_to_file
#get latest version number from file
LATEST_REFERENCE_APPLICATION_VERSION=$(head -n 1 ref_app_versions.txt | cut -d '_' -f 4)

CURRENT_REFERENCE_APPLICATION_VERSION=$(yq '.project.properties.referenceapplicationVersion' pom.xml)

if [ "$LATEST_REFERENCE_APPLICATION_VERSION" = "$CURRENT_REFERENCE_APPLICATION_VERSION" ]; then
  echo "Already using latest reference application version - $LATEST_REFERENCE_APPLICATION_VERSION"
else
  echo "Newer reference application version available"
  echo "Updating reference application version to $LATEST_REFERENCE_APPLICATION_VERSION"
  echo "Downloading modules"
  download_and_unzip_reference_application_modules "$LATEST_REFERENCE_APPLICATION_VERSION"

  #updating SystemAdministration owa file
  echo "Updating System Administration owa file"
  SYSADMIN_SHA=$(get_file_sha docker/web/owa/SystemAdministration.owa)
  encode_file_and_save_request_data_to_file_with_sha SystemAdministration.owa "$SYSADMIN_SHA"
  push_file_to_repo docker/web/owa/SystemAdministration.owa

  #replacing modules with newer version if there is one available
  ls referenceapplication*/modules >referenceapplication_modules.txt
  echo "Replacing modules with newer version available"
  while IFS=$'\n' read -r latest_module; do
    module_name=$(echo "$latest_module" | cut -d '-' -f 1)
    current_module=$(find docker/web/modules -name "$module_name-*" | cut -d '/' -f 4)

    #compare module version with current version
    if [ "$latest_module" = "$current_module" ]; then
      echo "Module $module_name is already up to date"
    else
      echo "Committing module version - $latest_module "
      echo "module: $latest_module, " >>commit-message.txt
      encode_file_and_save_request_data_to_file referenceapplication*/modules/"$latest_module"
      push_file_to_repo docker/web/modules/"$latest_module"

      version=$(echo "$latest_module" | cut -d '-' -f 2 | cut -d '.' -f 1-3)
      update_module_version_in_pom "$module_name" "$version"

      echo "Deleting outdated module - $current_module"
      MODULE_SHA=$(get_file_sha docker/web/modules/"$current_module")
      delete_file_with_sha "$current_module" "$MODULE_SHA"
    fi
  done <referenceapplication_modules.txt

  if grep -q "modules" response.json; then
    echo "Updating reference application version to $LATEST_REFERENCE_APPLICATION_VERSION"
  else
    echo "Error committing the changes"
  fi
  rm file.zip referenceapplication_modules.txt response.json data.json
  rm -r referenceapplication*
fi
rm response.html ref_app_versions.txt

sh scripts/update-version-numbers.sh "$TOKEN"
