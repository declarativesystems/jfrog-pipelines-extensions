pythonWheelDeployMain() {
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

  setupArtifactoryPypirc "$rtUrl" "$rtUser" "$rtApikey" "$repositoryName"
  runCommandAgainstSource "setup.py" "python setup.py bdist_wheel upload -r local"
}

execute_command pythonWheelDeployMain
