# save state of containers, less any auth credentials (in /run usually)
save_container_env_state() {
  resourceName=$1

  local clean
  clean=$(find_resource_variable "$resourceName" "clean")

  ensureTarball npmStateTarball $(pwd) "$clean"
}

execute_command save_container_env_state "%%context.resourceName%%"