awsCli() {
  local status;
  # aws cli v2 setup
  local awsKey
  awsKey=$(find_step_configuration_value "awsKey")
  local awsRegion
  awsRegion=$(find_step_configuration_value "awsRegion")
  local awsAccountId
  awsAccountId=$(find_step_configuration_value "awsAccountId")

  setupAwsCli "$awsKey" "$awsRegion"

  local commandsLen
  commandsLen=$(eval echo "$"step_configuration_commands_len)

  # to handle arrays, look for a field step_configuration_VARNAME_len
  # containing record count and then then munge each variable name like this:
  # * step_configuration_commands_len
  # * step_configuration_commands_0

  if [ "$commandsLen" -ge 0 ] ; then
    for (( i=0; i<commandsLen; ++i)); do
      local command
      command=$(eval echo "$"step_configuration_commands_${i})

      if [ -n "$command" ] ; then
        commandInterpolated=$(eval echo "$command")
        echo "running command: ${commandInterpolated}"
        eval echo "$commandInterpolated"
        status=$?

        if $command ; then
          echo "OK"
        else
          echo "FAILED!"
          status=1
        fi
      else
        echo "empty command in commands array!"
        status=1
        break
      fi
    done
  else
    echo "parameter 'commands' is missing"
    status=1
  fi
  return "$status"
}

execute_command awsCli
