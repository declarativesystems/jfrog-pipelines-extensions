artifactoryDownload() {
  local status
  local rtId
  rtId=$(find_step_configuration_value "sourceArtifactory")

  local path
  path=$(find_step_configuration_value "path")

  local target
  target=$(find_step_configuration_value "target")

  if [ -n "$rtId" ] && [ -n "$path" ]; then
    setupJfrogCliRt "$rtId"

    if [ -z "$target" ] ; then
      target=$(basename "$path")
      echo "setting target:${target}"
    fi

    echo "downloading ${path} to ${target}"
    jfrog rt download "$path" "$target"

    if [ -f "$target" ] ; then
      local pipeline_variable
      pipeline_variable="res_${step_name}_resourcePath=$(pwd)/${target}"
      echo "adding pipeline variable: ${pipeline_variable}"
      add_pipeline_variables "res_${step_name}_resourcePath=$(pwd)/${target}"
      status=0
    else
      echo "jfrog rt download succeeded but no file was downloaded to target:${target}"
      status=1
    fi
  else
    echo "one or more parameters missing:"
    echo "  sourceArtifactory:${rtId}"
    echo "  path:${path}"
    echo "  target:${target}"
    status=1
  fi

  return "$status"
}



execute_command artifactoryDownload