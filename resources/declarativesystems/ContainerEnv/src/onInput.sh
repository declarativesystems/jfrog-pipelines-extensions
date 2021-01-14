# login to artifactory and recover container state
restore_container_env_state() {
  resourceName=$1

  # artifactory setup
  local rtId
  rtId=$(find_resource_variable "$resourceName" "sourceArtifactory")
  setupArtifactoryPodman "$rtId"

  restoreTarball containerStateTarball "$containerStateTarball"
}

execute_command restore_container_env_state "%%context.resourceName%%"