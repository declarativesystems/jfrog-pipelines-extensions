goRtPublish() {
  local repositoryName=$1
  local buildName=$2
  local buildNumber=$3
  local status
  echo "publishing ${buildName}:${buildNumber} to artifactory repository ${repositoryName}..."
  runCommandAgainstSource ".goreleaser.yml" \
    "jfrog rt upload \
    --build-number ${buildNumber} \
    --build-name ${buildName} \
    dist/*.tar.gz ${repositoryName}/${buildName}/"
  status=$?
  echo "status: $status"

  return "$status"
}

goReleaserMain() {
  local status

  # artifactory setup
  local rtId
  rtId=$(find_step_configuration_value "sourceArtifactory")
  local repositoryName
  repositoryName=$(find_step_configuration_value "repositoryName")
  local buildName
  buildName=$(find_step_configuration_value "buildName")
  local buildNumberVar
  buildNumberVar=$(find_step_configuration_value "buildNumber")
  local buildNumber
  buildNumber=$(eval echo "$buildNumberVar")


  # GoReleaser
  if [ -n "$rtId" ] && [ -n "$repositoryName" ] && [ -n "$buildName" ] && [ -n "$buildNumber" ] ; then
    # GAH https://github.com/goreleaser/goreleaser/pull/1825 prevents us
    # publishing snapshot to artifactory so build them with `goreleaser`
    # and then upload to a generic repository
    #    export ARTIFACTORY_DEPLOY_USERNAME=$rtUser
    #    export ARTIFACTORY_DEPLOY_SECRET=$rtApikey
    #    export ARTIFACTORY_DEPLOY_REPOSITORY_URL="${rtUrl}/${repositoryName}"


    # todo - work out what to do with releases vs snapshot
    # todo - resolve build artifacts from artifactory
    if setupJfrogCliRt "$rtId" ; then
      echo "building tarball with goreleaser..."
      runCommandAgainstSource ".goreleaser.yml" "goreleaser --snapshot" && goRtPublish "$repositoryName" "$buildName" "$buildNumber"
      status=$?
    fi
  else
    echo "one or more parameters missing:"
    echo "  sourceArtifactory:${rtId}"
    echo "  repositoryName:${repositoryName}"
    echo "  buildName:${buildName}"
    echo "  buildNumber:${buildNumber}"
    status=1
  fi

  return "$status"
}


execute_command goReleaserMain