setupPodman() {
  # artifactory setup
  local rtId
  rtId=$(find_step_configuration_value "sourceArtifactory")

  setupArtifactoryPodman "$rtId"
}

execute_command setupPodman
