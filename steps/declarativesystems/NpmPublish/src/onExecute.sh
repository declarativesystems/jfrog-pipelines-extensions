
# publish to artifactory
# @param $1 the URL of the NPM repository
# @param $2 extra npm args
npmPublish() {
  local rtNpmUrl=$1
  local npmArgs=$2
  # npm gives a hard to follow error if package VERSION already published so
  # lookup whether this version already exists...

  # grab package name and version from package.json
  local packageName
  packageName=$(jq -r .name < package.json)
  local packageVersion
  packageVersion=$(jq -r .version < package.json)
  echo "checking if package ${packageName} version ${packageVersion} already exists..."
  if npm search "$packageName" | awk -F\| '{ gsub(/ /, "", $5); print $5 }' | grep "$packageVersion" ; then
    echo "Package ${packageName} version ${packageVersion} already exists"
    echo "Increment version number or remove old version from artifactory to publish"
    status=1
  else
    publishCommand="npm publish --registry ${rtNpmUrl} ${npmArgs}"

    echo "running: ${publishCommand}"
    $publishCommand
    status=$?
  fi
  return "$status"
}

npmPublishMain() {
  # artifactory server for resolve & deploy
  local rtId
  rtId=$(find_step_configuration_value "sourceArtifactory")

  # repository for artifact publishing
  local repositoryName
  repositoryName=$(find_step_configuration_value "repositoryName")

  local npmArgs
  npmArgs=$(find_step_configuration_value "npmArgs")

  local rtNpmUrl
  rtNpmUrl=$(npmRegistryUrl "$rtId" "$repositoryName")

  setupArtifactoryNpm "$rtId" "$repositoryName"
  runCommandAgainstSource "package.json" "npmPublish ${rtNpmUrl} ${npmArgs}"
}

execute_command npmPublishMain
