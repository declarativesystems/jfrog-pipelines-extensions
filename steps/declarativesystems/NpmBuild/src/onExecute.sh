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

npmBuildMain() {
  # grab a bunch of environment variables - since whole of pipelines is
  # basically a huge BASH script be extra careful and scope everything `local`

  local rtId
  rtId=$(find_step_configuration_value "sourceArtifactory")

  # the unified repository for resolving all artifacts
  local repositoryName
  repositoryName=$(find_step_configuration_value "repositoryName")

  local npmArgs
  npmArgs=$(find_step_configuration_value "npmArgs")

  setupArtifactoryNpm "$rtId" "$repositoryName"
  runCommandAgainstSource "package.json" "npmInstall && npmBuild"
}

execute_command npmBuildMain
