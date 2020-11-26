artifactoryDownload() {
  local path
  path=$(find_step_configuration_value "path")

  local target
  target=$(find_step_configuration_value "target") || basename "$path"

  local rtId
  rtId=$(find_step_configuration_value "sourceArtifactory")
  setupJfrogCliRt "$rtId"

  echo "downloading ${path} to ${target}"
  jfrog rt download "$path" "$target"

  add_pipeline_variables "res_${step_name}_resourcePath=$(pwd)/${target}"

}



execute_command artifactoryDownload