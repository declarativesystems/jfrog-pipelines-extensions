pythonWheelDeploy() {
  local rtId
  rtId=$(find_step_configuration_value "sourceArtifactory")
  local repositoryName
  repositoryName=$(find_step_configuration_value "repositoryName")

  setupArtifactoryPypirc "$rtId" "$repositoryName"
  runCommandAgainstSource "setup.py" "python setup.py bdist_wheel upload -r local"
}

execute_command pythonWheelDeploy
