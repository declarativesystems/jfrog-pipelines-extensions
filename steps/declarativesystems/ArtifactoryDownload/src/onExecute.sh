artifactoryDownload() {
  local status
  local rtId
  rtId=$(find_step_configuration_value "sourceArtifactory")

  local path
  path=$(find_step_configuration_value "path")

  local target
  target=$(find_step_configuration_value "target") || basename "$path"

  if [ -n "$rtId" ] && [ -n "$path" ]; then
    setupJfrogCliRt "$rtId"

    echo "downloading ${path} to ${target}"
    jfrog rt download "$path" "$target"

    local pipeline_variable
    pipeline_variable="res_${step_name}_resourcePath=$(pwd)/${target}"
    echo "adding pipeline variable: ${pipeline_variable}"
    add_pipeline_variables "res_${step_name}_resourcePath=$(pwd)/${target}"
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