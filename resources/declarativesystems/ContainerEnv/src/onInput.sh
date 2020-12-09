# login to artifactory and recover container state
restore_container_env_state() {
  resourceName=$1
  restore_run_files containerStateTarball "$containerStateTarball"
  if [ -f "$containerStateTarball" ] ; then
    local containerStateTarballSize
    containerStateTarballSize=$(fileSizeMb "$containerStateTarball")
    tar -zxf "$containerStateTarball" -C /
    echo "restored container state (${containerStateTarballSize}MB)"
  fi

  # artifactory setup
  local rtId
  rtId=$(find_resource_variable "$resourceName" "sourceArtifactory")
  setupArtifactoryPodman "$rtId"
}

execute_command restore_container_env_state "%%context.resourceName%%"