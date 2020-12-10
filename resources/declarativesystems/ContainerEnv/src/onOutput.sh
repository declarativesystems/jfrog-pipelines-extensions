# save state of containers, less any auth credentials (in /run usually)
save_container_env_state() {
  resourceName=$1

  local clean
  clean=$(find_resource_variable "$resourceName" "clean")
  if [ "$clean" = true ] ; then
    echo "cleaning container state"
    rm -rf "$containerStorageDir/*"
  fi

  echo "compressing and saving files for next step"
  if [ -d "$containerStorageDir" ] ; then
    tar -zcf "$containerStateTarball" "$containerStorageDir"
    add_run_files "$containerStateTarball" containerStateTarball

    local containerStateTarballSize
    containerStateTarballSize=$(fileSizeMb "$containerStateTarball")
    echo "saved container state (${containerStateTarballSize}MB)"
  else
    echo "no container directory:${containerStorageDir} - skipping"
  fi
}

execute_command save_container_env_state "%%context.resourceName%%"