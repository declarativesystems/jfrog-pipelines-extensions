# login to artifactory and recover container state
restore_npm_env_state() {
  local resourceName="$1"

  # artifactory setup
  local rtId
  rtId=$(find_resource_variable "$resourceName" "sourceArtifactory")

  # the unified repository for resolving all artifacts
  local repositoryName
  repositoryName=$(find_resource_variable "$resourceName" "repositoryName")

  setupArtifactoryNpm "$rtId" "$repositoryName"
  restoreTarball npmStateTarball "$(pwd)"
}

execute_command restore_npm_env_state "%%context.resourceName%%"