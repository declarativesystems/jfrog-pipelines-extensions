# =====[DO NOT EDIT THIS FILE]=====
# run a command inside `$sourceLocation` (configuration/sourceLocation) or
# `intermediateBuildDir` if sourceLocation not set
# @param $1 file to look for inside source directory (eg package.json)
# @param $2 command to run
runCommandAgainstSource() {
  local markerFile=$1
  local commandToRun=$2
  local status=255
  # pipelines.yml $variables need to be eval'ed to read the value
  local sourceLocationVar
  sourceLocationVar=$(find_step_configuration_value "sourceLocation")
  if [ "$sourceLocationVar" == "" ]; then
    # fallback to intermediateBuildDir
    sourceLocationVar="intermediateBuildDir"
  fi
  local sourceLocation
  sourceLocation=$(eval echo "$sourceLocationVar")
  echo "checking ${sourceLocation} for ${markerFile}"
  if [ -f "${sourceLocation}/${markerFile}" ]; then
    echo "[debug] ${commandToRun}"
    pushd "$sourceLocation" && eval "$commandToRun"
    status=$?
  else
    echo "no ${markerFile} in sourceLocation - current directory:"
    tree -L 1
    status=1
  fi

  return "$status"
}

# setup jfrog/artifactory CLI
# working: setup ~/.jfrog and ping server
# not working: jfrog rt npm-install
setupJfrogCliRt() {
  export CI=true
  local rtId=$1
  local rtUrl=$2
  local rtUser=$3
  local rtApikey=$4
  echo "Setup artifactory id:${rtId} url:${rtUrl} user:${rtUser} rtApikey:$([[ "$rtApikey" != "" ]] && echo "REDACTED")..."
  jfrog rt config --url "$rtUrl" --user "$rtUser" --apikey "$rtApikey" "$rtId"

  echo "Artifactory id=${rtId}: $(jfrog rt ping)"
}

# munge the NPM repository URL
# @param $1 the base URL of this artifactory
# @param $2 repository name
npmRegistryUrl() {
  local rtUrl=$1
  local repositoryName=$2

  echo "${rtUrl}/api/npm/${repositoryName}/"
}

setupArtifactoryPodman() {
  local rtUrl=$1
  local rtUser=$2
  local rtApikey=$3
  local status

  if [ -n "$rtUrl" ] && [ -n "$rtUser" ] && [ -n "$rtApikey" ] ; then
    echo "setting up podman for artifactory: ${rtUrl}..."
    podman login --username "$rtUser" --password "$rtApikey" "$rtUrl"
    status=$?
  else
    echo "failed to setup podman for artifactory, one ore more required parameters missing - rtUrl: ${rtUrl} rtUser: ${rtUser} rtApikey: $([[ "$rtApikey" != "" ]] && echo "REDACTED")"
    status=1
  fi
  return "$status"
}

# setup NPM to use artifactory - this is the instructions from "set me up" and
# also the magic npm REST url
# @see https://www.jfrog.com/confluence/display/JFROG/npm+Registry
#
# @param $1 artifactory URL
# @param $2 artifactory user
# @param $3 artifactory apikey
# @param $4 repository name
setupArtifactoryNpm() {
  local rtUrl=$1
  local rtUser=$2
  local rtApikey=$3
  local repositoryName=$4

  # magic URL that generates ~/.npmrc - this guy is the same no matter what
  # your repository is called and authorises you for all repos your account
  # has access to
  local rtNpmAuthUrl="${rtUrl}/api/npm/auth"
  local rtNpmUrl
  rtNpmUrl=$(npmRegistryUrl "$rtUrl" "$repositoryName")

  local status
  echo "Setup npm url:${rtUrl} user:${rtUser} rtApikey:$([[ "$rtApikey" != "" ]] && echo "REDACTED")..."

  # grab the magic file, destroying any existing npmrc
  curl -u "${rtUser}:${rtApikey}" "${rtNpmAuthUrl}" >~/.npmrc

  # tell npm to use this realm
  echo "configuring npm registry: ${rtNpmUrl}"
  npm config set registry "$rtNpmUrl"

  # there is an `npm ping` command but it just hangs if used on Artifactory so
  # do a search and grep for `200 OK ARTIFACTORYURL` which checks that npm
  # working AND talking to the right server. Requires verbose mode!
  npmTest=$(npm search npm --verbose 2>&1)

  if echo "$npmTest" | grep "GET 200 ${rtUrl}"; then
    echo "Artifactory id=${rtId}: OK"
    status=0
  else
    echo "Artifactory id=${rtId}: FAILED, output of 'npm search npm':"
    echo "$npmTest"
    status=1
  fi

  return $status
}

setupAwsCli() {
  local rtUrl=$1
  local rtUser=$2
  local rtApikey=$3
  local repositoryName=$4

  if [ -n "$awsRegion" ] && [ -n "$awsAccessKeyId" ] && [ -n "$awsSecretAccessKey" ] ; then
    echo "setting up AWS CLI for access key: ${awsAccessKeyId}..."
    mkdir -p ~/.aws

    cat <<EOF >~/.aws/config
[default]
region=${awsRegion}
output=json
EOF

    cat <<EOF >~/.aws/credentials
[default]
aws_access_key_id = ${awsAccessKeyId}
aws_secret_access_key = ${awsSecretAccessKey}
EOF
    status=$?
  else
    echo "failed to setup AWS CLI, one ore more required parameters missing - awsRegion:${awsRegion} awsAccessKeyId:${awsAccessKeyId} awsSecretAccessKey:$([[ "$awsSecretAccessKey" != "" ]] && echo "REDACTED")"
    status=1
  fi
  return "$status"
}

setupArtifactoryPip() {
  local rtUrl=$1
  local rtUser=$2
  local rtApikey=$3
  local repositoryName=$4
  # remove leading https://
  local rtUrlStripped=$(echo "$rtUrl" | sed -r "s/http(s)?:\/\///")

  mkdir -p ~/.pip
  cat <<EOF > ~/.pip/pip.conf
[global]
index-url = https://${rtUser}:${rtApikey}@${rtUrlStripped}/api/pypi/${repositoryName}/simple
EOF
  echo "[debug] pip configured to use artifactory repo:${repositoryName}"
}

setupArtifactoryPypirc() {
  local rtUrl=$1
  local rtUser=$2
  local rtApikey=$3
  local repositoryName=$4

  cat <<EOF > ~/.pypirc
[distutils]
index-servers = local
[local]
repository: ${rtUrl}/api/pypi/${repositoryName}
username: ${rtUser}
password: ${rtApikey}
EOF
  echo "[debug] setuptools configured to use artifactory repo:${repositoryName}"
}
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