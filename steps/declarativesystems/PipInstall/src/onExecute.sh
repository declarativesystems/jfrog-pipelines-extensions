pipInstall() {
  local rtId
  rtId=$(find_step_configuration_value "sourceArtifactory")
  local repositoryName
  repositoryName=$(find_step_configuration_value "repositoryName")

  setupArtifactoryPip "$rtId" "$repositoryName"
  runCommandAgainstSource "setup.py" "pip install ."
}

execute_command pipInstall
