setupPythonEnv() {
  local resourceName="$1"

  local rtId
  rtId=$(find_resource_variable "$resourceName" "sourceArtifactory")
  local repositoryName
  repositoryName=$(find_resource_variable "$resourceName" "repositoryName")

  setupArtifactoryPip "$rtId" "$repositoryName"
  setupArtifactoryPypirc "$rtId" "$repositoryName"
}

execute_command setupPythonEnv "%%context.resourceName%%"
