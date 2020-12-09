# login to artifactory and recover container state
restore_container_env_state() {
  resourceName=$1

  # artifactory setup
  local rtId
  rtId=$(find_resource_variable "$resourceName" "sourceArtifactory")
  setupArtifactoryPodman "$rtId"

  echo "attempting container state recovery"
  restore_run_files containerStateTarball "$containerStateTarball"
  if [ -f "$containerStateTarball" ] ; then
    local containerStateTarballSize
    containerStateTarballSize=$(fileSizeMb "$containerStateTarball")
    tar -zxf "$containerStateTarball" -C /
    echo "restored container state (${containerStateTarballSize}MB)"
  fi
}

execute_command restore_container_env_state "%%context.resourceName%%"