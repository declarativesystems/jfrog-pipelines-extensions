npmInstall() {
  local installCommand
  installCommand="npm install ${npmArgs}"

  echo "running: ${installCommand}"
  $installCommand
}

npmBuild() {
  local buildCommand
  buildCommand=$(find_step_configuration_value "buildCommand") || echo "npm build ${npmArgs}"

  echo "running: ${buildCommand}"
  $buildCommand
}

saveFilesForNextStep() {
  # built-in utility function to make files available to next stage
  # https://www.jfrog.com/confluence/display/JFROG/Creating+Stateful+Pipelines
  add_run_files . "intermediateBuildDir"
}

npmBuildMain() {
  # grab a bunch of environment variables - since whole of pipelines is
  # basically a huge BASH script be extra careful and scope everything `local`

  local rtName
  rtName=$(find_step_configuration_value "sourceArtifactory")
  local rtUrl
  rtUrl=$(eval echo "$"int_"$rtName"_url)
  local rtUser
  rtUser=$(eval echo "$"int_"$rtName"_user)
  local rtApikey
  rtApikey=$(eval echo "$"int_"$rtName"_apikey)

  # the unified repository for resolving all artifacts
  local repositoryName
  repositoryName=$(find_step_configuration_value "repositoryName")

  local npmArgs
  npmArgs=$(find_step_configuration_value "npmArgs")

  setupArtifactoryNpm "$rtUrl" "$rtUser" "$rtApikey" "$repositoryName"
  runCommandAgainstSource "package.json" "npmInstall && npmBuild && saveFilesForNextStep"
}

execute_command npmBuildMain
