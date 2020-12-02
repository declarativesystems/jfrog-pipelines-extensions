artifactoryUpload() {
  local status
  local rtId
  rtId=$(find_step_configuration_value "sourceArtifactory")

  local source
  source=$(find_step_configuration_value "source")

  local path
  path=$(find_step_configuration_value "path")

  if [ -n "$rtId" ] && [ -n "$path" ] && [ -f "$source" ]; then
    setupJfrogCliRt "$rtId"

    echo "publishing ${source} to artifactory path:${path}..."
    jfrog rt upload \
      --build-number "$buildNumber" \
      --build-name "$buildName" \
      "$source" "$path"
    status=$?
  else
    echo "one or more parameters missing:"
    echo "  sourceArtifactory:${rtId}"
    echo "  path:${path}"
    echo "  source:${source} exists:"$(test -f "$source" && echo "yes" || echo "no")

    status=1
  fi
  return "$status"
}

execute_command artifactoryUpload