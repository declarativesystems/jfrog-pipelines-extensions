goReleaserSnapshot() {
  local status
  runCommandAgainstSource ".goreleaser.yml" "goreleaser --snapshot"

  status=$?
  echo "status: $status"

  return "$status"
}

goRtPublish() {
  local repositoryName=$1
  local buildName=$2
  local buildNumber=$3
  local status
  echo "publishing ${buildName}:${buildNumber} to artifactory repository ${repositoryName}..."
  runCommandAgainstSource ".goreleaser.yml" "jfrog rt upload dist/*.tar.gz ${repositoryName} --build-name ${buildName} --build-number ${buildNumber}"
  status=$?
  echo "status: $status"

  return "$status"
}

goReleaserMain() {
  local status

  # artifactory setup
  local rtName
  rtName=$(find_step_configuration_value "sourceArtifactory")
  local rtUrl
  rtUrl=$(eval echo "$"int_"$rtName"_url)
  local rtUser
  rtUser=$(eval echo "$"int_"$rtName"_user)
  local rtApikey
  rtApikey=$(eval echo "$"int_"$rtName"_apikey)

  local repositoryName
  repositoryName=$(find_step_configuration_value "repositoryName")
  local buildName
  buildName=$(find_step_configuration_value "buildName")
  local buildNumberVar
  buildNumberVar=$(find_step_configuration_value "buildNumber")
  local buildNumber
  buildNumber=$(eval echo "$buildNumberVar")


  # GoReleaser
  if [ -n "$rtUser" ] && [ -n "$rtApikey" ] && [ -n "$rtUrl" ] && [ -n "$buildName" ] && [ -n "$buildNumber" ] ; then
    # GAH https://github.com/goreleaser/goreleaser/pull/1825 prevents us
    # publishing snapshot to artifactory so build them with `goreleaser`
    # and then upload to a generic repository
    #    export ARTIFACTORY_DEPLOY_USERNAME=$rtUser
    #    export ARTIFACTORY_DEPLOY_SECRET=$rtApikey
    #    export ARTIFACTORY_DEPLOY_REPOSITORY_URL="${rtUrl}/${repositoryName}"


    # todo - work out what to do with releases vs snapshot
    # todo - resolve build artifacts from artifactory
    local rtId=$rtName
    if setupJfrogCliRt "$rtId" "$rtUrl" "$rtUser" "$rtApikey" ; then
      echo "building tarball with goreleaser..."
      goReleaserSnapshot && goRtPublish "$repositoryName" "$buildName" "$buildNumber"
      status=$?
    fi
  else
    echo "one or more parameters missing:"
    echo "  sourceArtifactory:${sourceArtifactory}"
    echo "  repositoryName:${repositoryName}"
    echo "  buildName:${buildName}"
    echo "  buildNumber:${buildNumber}"
    status=1
  fi

  return "$status"
}


execute_command goReleaserMain