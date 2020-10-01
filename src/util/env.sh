function a.util.get_env_vars() {
  declare -xp | sed 's/^declare -x //'
}
export -f a.util.get_env_vars

function a.util.set_env_var() {
  # usage: set_env_var "VAR_NAME" "default_value"
  # if "VAR_NAME" is unset, set "default_value" to it and export it
  # else "VAR_NAME" is already set, re-set its value to itself and export it

  local _name=$1
  local _default=$2

  if [ -z ${!_name+x} ]; then
    export ${_name}="${_default}"
  else
    export ${_name}="${!_name}"
  fi
}
export -f a.util.set_env_var

function a.util.set_env_var_upper2lower() {
  while read line; do
    var_name=$(echo $line | awk -F= '{print $1}')
    var_value=$(echo "${line#*=}" | tr -d \")

    lower_var_name=${var_name,,}
    export ${lower_var_name}="${var_value}"
  done < <(get_env_vars | grep "^[A-Z][A-Z0-9_]*")
}
export -f a.util.set_env_var_upper2lower

function a.util.env_var_to_yaml() {
  while read line; do
    var_name=$(echo $line | awk -F= '{print $1}')
    var_value=$(echo "${line#*=}" | tr -d \")

    if [[ "X${var_value}" == "X" ]]; then
      echo "${var_name}: ''"
    elif [[ "${var_value}" == 'true' || "${var_value}" == 'false' ]]; then
      echo "${var_name}: ${var_value}"
    else
      echo "${var_name}: \"${var_value}\""
    fi

  done < <(get_env_vars | sort)
}
export -f a.util.env_var_to_yaml

# eg:
# args: 192.168.1.1 192.168.1.2 192.168.1.3
# output: [ "192.168.1.1", "192.168.1.2", "192.168.1.3" ]
function a.util.shell_array_to_yaml_list() {
  local arr=("$@")

  echo -n '[ '
  for i in "${!arr[@]}"; do
    if [[ $i -eq 0 ]]; then
      echo -n "\"${arr[i]}\""
    else
      echo -n ", \"${arr[i]}\""
    fi
  done

  echo -n ' ]'
  echo
}
export -f a.util.shell_array_to_yaml_list

# eg:
# args: 192.168.1.1 192.168.1.2 192.168.1.3
# output:
# - 192.168.1.1
# - 192.168.1.2
# - 192.168.1.3
function a.util.shell_array_to_yaml_dash_list() {
  local arr=("$@")

  echo
  for i in "${!arr[@]}"; do
    echo -n "- ${arr[i]}"
    echo
  done
}
export -f a.util.shell_array_to_yaml_dash_list
