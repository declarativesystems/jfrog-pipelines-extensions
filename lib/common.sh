# Print the size of `filename` in MB
# $1 filename
fileSizeMb() {
  echo $(($(stat --printf="%s" "$1") / 1024 / 1024))
}

# run a command inside `$sourceLocation` (configuration/sourceLocation) if set
# otherwise just use the current directory
# @param $1 file to look for (eg `package.json`) which means we are in the right
#   directory and not lost
# @param $2 command to run
runCommandAgainstSource() {
  local markerFile=$1
  local commandToRun=$2
  local status=255
  # pipelines.yml $variables need to be eval'ed to read the value
  local sourceLocationVar
  sourceLocationVar=$(find_step_configuration_value "sourceLocation")
  local sourceLocation
  sourceLocation=$(eval echo "$sourceLocationVar")

  if [ -n "$sourceLocation" ]; then
    echo "entering sourceLocation: ${sourceLocation}"
    pushd "$sourceLocation" || (
      echo "no such directory: ${sourceLocation}"
      return 1
    )
  fi

  if [ -f "${markerFile}" ]; then
    echo "[debug] ${commandToRun}"
    pushd "$sourceLocation" && eval "$commandToRun"
    status=$?
  else
    echo "no ${markerFile} in $(pwd), found:"
    tree -L 1
    status=1
  fi

  if [ -n "$sourceLocation" ]; then
    echo "leaving sourceLocation..."
    popd || (
      echo "failed to return to previous directory!"
      return 1
    )
  fi

  return "$status"
}

# grab a bunch of artifactory settings and put in global scope to reduce code
# duplication. You must call this method before accessing the variables it
# exposes to be sure of a fresh set
scopeArtifactoryVariables() {
  local rtId=$1

  rtUrl=$(eval echo "$"int_"$rtId"_url)
  rtUser=$(eval echo "$"int_"$rtId"_user)
  rtApikey=$(eval echo "$"int_"$rtId"_apikey)
}

# setup jfrog/artifactory CLI
# working: setup ~/.jfrog and ping server
# not working: jfrog rt npm-install
setupJfrogCliRt() {
  local rtId=$1
  local rtUrl
  local rtUser
  local rtApikey
  scopeArtifactoryVariables "$rtId"

  export CI=true
  echo "Setup artifactory id:${rtId} url:${rtUrl} user:${rtUser} rtApikey:$([[ "$rtApikey" != "" ]] && echo "REDACTED")..."
  jfrog rt config --url "$rtUrl" --user "$rtUser" --apikey "$rtApikey" "$rtId"

  echo "Artifactory id=${rtId}: $(jfrog rt ping)"
}

# munge the NPM repository URL
# @param $1 the base URL of this artifactory
# @param $2 repository name
npmRegistryUrl() {
  local rtId=$1
  local repositoryName=$2

  local rtUrl
  local rtUser
  local rtApikey
  scopeArtifactoryVariables "$rtId"
  echo "${rtUrl}/api/npm/${repositoryName}/"
}

setupArtifactoryPodman() {
  local rtId=$1

  local rtUrl
  local rtUser
  local rtApikey
  scopeArtifactoryVariables "$rtId"
  local status

  if [ -n "$rtUrl" ] && [ -n "$rtUser" ] && [ -n "$rtApikey" ]; then
    echo "setting up podman for artifactory: ${rtUrl}..."

    # store container-related settings and data in one directory so that
    # it can be copied between steps
    add_run_variables containerStorageDir="/containers"

    # reconfigure container subsystem to use this directory (custom script in
    # image)
    container_storage_setup "$containerStorageDir"
    echo "container storage dir set to $containerStorageDir"

    # intermediate tarball to copy between steps
    add_run_variables containerStateTarball="/tmp/containers.tar.gz"

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
  local rtId=$1
  local repositoryName=$2

  local rtUrl
  local rtUser
  local rtApikey
  scopeArtifactoryVariables "$rtId"

  # magic URL that generates ~/.npmrc - this guy is the same no matter what
  # your repository is called and authorises you for all repos your account
  # has access to
  local rtNpmAuthUrl="${rtUrl}/api/npm/auth"
  local rtNpmUrl
  rtNpmUrl=$(npmRegistryUrl "$rtId" "$repositoryName")

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
  local awsKey=$1
  local awsRegion=$2

  local awsAccessKeyId
  awsAccessKeyId=$(eval echo "$"int_"$awsKey"_accessKeyId)
  local awsSecretAccessKey
  awsSecretAccessKey=$(eval echo "$"int_"$awsKey"_secretAccessKey)

  if [ -n "$awsRegion" ] && [ -n "$awsAccessKeyId" ] && [ -n "$awsSecretAccessKey" ]; then
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
  local rtId=$1
  local repositoryName=$2

  local rtUrl
  local rtUser
  local rtApikey
  scopeArtifactoryVariables "$rtId"

  # remove leading https://
  local rtUrlStripped
  rtUrlStripped=$(echo "$rtUrl" | sed -r "s/http(s)?:\/\///")

  mkdir -p ~/.pip
  cat <<EOF >~/.pip/pip.conf
[global]
index-url = https://${rtUser}:${rtApikey}@${rtUrlStripped}/api/pypi/${repositoryName}/simple
EOF
  echo "[debug] pip configured to use artifactory repo:${repositoryName}"
}

setupArtifactoryPypirc() {
  local rtId=$1
  local repositoryName=$2

  local rtUrl
  local rtUser
  local rtApikey
  scopeArtifactoryVariables "$rtId"

  cat <<EOF >~/.pypirc
[distutils]
index-servers = local
[local]
repository: ${rtUrl}/api/pypi/${repositoryName}
username: ${rtUser}
password: ${rtApikey}
EOF
  echo "[debug] setuptools configured to use artifactory repo:${repositoryName}"
}

setupArtifactoryPoetry() {
  local rtId=$1
  local repositoryName=$2

  local rtUrl
  local rtUser
  local rtApikey
  scopeArtifactoryVariables "$rtId"
  mkdir -p ~/.config/pypoetry/

  cat <<EOF >~/.config/pypoetry/auth.toml
[http-basic]
[http-basic.${repositoryName}]
username = "${rtUser}"
password = "${rtApikey}"
EOF

  cat <<EOF >~/.config/pypoetry/config.toml
[repositories]
[repositories.${repositoryName}]
url = "${rtUrl}/api/pypi/${repositoryName}"
EOF

  echo "[debug] poetry configured to use artifactory repo:${repositoryName}"
}

# create/update a tarball from files at $tarballPath and add the files to
# pipeline with name $tarballName
function ensureTarball() {
  local tarballName="$1"
  local tarballPath="$2"
  local clean="$3"

  # Keeping tarballs in build workspace when they are no longer needed makes the
  # whole build go slow, so delete them if no longer needed. We use a well known
  # name `clean` as the variable to indicatewhen to do this
  if [ "$clean" = true ]; then
    echo "cleaning container state"
    rm -rf "${containerStorageDir:?}"/*
  fi


  echo "updating state tarball: ${tarballName}"
  if [ -d "$tarballPath" ]; then
    tar -zcf "$tarballName" "$tarballPath"
    add_run_files "$tarballPath" "$tarballName"

    local tarballSize
    tarballSize=$(fileSizeMb "$tarballPath")
    echo "saved state tarball: ${tarballName} (${tarballSize}MB)"
  else
    echo "no such directory:${tarballPath} - skipping"
  fi
}

function restoreTarball() {
  tarballName="$1"
  tarballPath="$2"
  echo "attempting state recovery: ${tarballName}"
  restore_run_files "$tarballName" "$tarballPath"
  if [ -f "$tarballPath" ]; then
    local tarballSize
    tarballSize=$(fileSizeMb "$tarballPath")
    tar -zxf "$tarballPath" -C /
    echo "restored state: ${tarballName} (${tarballSize}MB)"
  fi
}
