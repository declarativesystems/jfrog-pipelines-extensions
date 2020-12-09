# save state of containers, less any auth credentials (in /run usually)
save_container_env_state() {
  resourceName=$1
  echo "compressing and saving files for next step"
  tar -zcf "$containerStateTarball" "$containerStorageDir"
  add_run_files "$containerStateTarball" containerStateTarball

  local containerStateTarballSize
  containerStateTarballSize=$(fileSizeMb "$containerStateTarball")
  echo "saved container state (${containerStateTarballSize}MB)"
}

execute_command save_container_env_state "%%context.resourceName%%"