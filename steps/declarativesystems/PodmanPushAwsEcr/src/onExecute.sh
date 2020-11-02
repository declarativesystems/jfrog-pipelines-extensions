
tagImageAndPush() {
  local awsRegion=$1
  local awsAccountId=$2
  local status

  # a complete image (repo+name+tag) to read from artifactory
  local artifactoryImage
  artifactoryImage=$(find_step_configuration_value "artifactoryImage")

  # ECR image name and tag (separate)
  local ecrImageName
  ecrImageName=$(find_step_configuration_value "ecrImageName")
  local ecrImageTag
  ecrImageTag=$(find_step_configuration_value "ecrImageTag")

  local containerCmd="podman"
  local containerPullCmd="${containerCmd} pull"
  local containerPushCmd="${containerCmd} push"

  if [ -n "$awsRegion" ] && [ -n "$awsAccountId" ] && [ -n "$artifactoryImage" ] && [ -n "$ecrImageName" ] && [ -n "$ecrImageTag" ]; then

    # variables ok, munge the image name
    local awsNamespace="${awsAccountId}.dkr.ecr.${awsRegion}.amazonaws.com"
    local ecrImage="${awsNamespace}/${ecrImageName}:${ecrImageTag}"

    echo "re-tagging and publishing image ${artifactoryImage} to ${ecrImage}..."

    # podman pull ...
    $containerPullCmd "$artifactoryImage"

    # podman tag...
    $containerCmd tag "$artifactoryImage" "$ecrImage"

    # setup docker for ECR push
    aws ecr get-login-password --region "$awsRegion" \
      | $containerCmd login --username AWS --password-stdin "$awsNamespace"

    # podman push...
    $containerPushCmd "$ecrImage"
    status=$?
  else
    echo "one or more parameters missing:"
    echo "  awsRegion:${awsRegion}"
    echo "  awsAccountId:${awsAccountId}"
    echo "  artifactoryImage:${artifactoryImage}"
    echo "  ecrImageName:${ecrImageName}"
    echo "  ecrImageTag:${ecrImageTag}"
    status=1
  fi
  return "$status"
}

podmanPushAwsEcr() {
  # artifactory setup
  local rtName
  rtName=$(find_step_configuration_value "sourceArtifactory")
  local rtUrl
  rtUrl=$(eval echo "$"int_"$rtName"_url)
  local rtUser
  rtUser=$(eval echo "$"int_"$rtName"_user)
  local rtApikey
  rtApikey=$(eval echo "$"int_"$rtName"_apikey)

  setupArtifactoryPodman "$rtUrl" "$rtUser" "$rtApikey"

  # aws cli v2 setup
  local awsKey
  awsKey=$(find_step_configuration_value "awsKey")
  local awsRegion
  awsRegion=$(find_step_configuration_value "awsRegion")
  local awsAccountId
  awsAccountId=$(find_step_configuration_value "awsAccountId")

  awsAccessKeyId=$(eval echo "$"int_"$awsKey"_accessKeyId)
  awsSecretAccessKey=$(eval echo "$"int_"$awsKey"_secretAccessKey)
  setupAwsCli "$awsRegion" "$awsAccessKeyId" "$awsSecretAccessKey"


  tagImageAndPush "$awsRegion" "$awsAccountId"
}

execute_command podmanPushAwsEcr
