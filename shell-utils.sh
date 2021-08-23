#!/bin/bash

function valid_ipv4() {
  local ip=$1
  local stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && \
    ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    stat=$?
  fi
  return $stat
}
export -f valid_ipv4

function get_env_vars() {
  declare -xp | sed 's/^declare -x //'
}
export -f get_env_vars

function set_env_var() {
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
export -f set_env_var

function set_env_var_upper2lower() {
  while read line; do
    var_name=$(echo $line | awk -F= '{print $1}')
    var_value=$(echo "${line#*=}" | tr -d \")

    lower_var_name=${var_name,,}
    export ${lower_var_name}="${var_value}"
  done < <(get_env_vars | grep "^[A-Z][A-Z0-9_]*")
}
export -f set_env_var_upper2lower

function env_var_to_yaml() {
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
export -f env_var_to_yaml

# eg:
# args: 192.168.1.1 192.168.1.2 192.168.1.3
# output: [ "192.168.1.1", "192.168.1.2", "192.168.1.3" ]
function shell_array_to_yaml_list() {
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
export -f shell_array_to_yaml_list

# eg:
# args: 192.168.1.1 192.168.1.2 192.168.1.3
# output:
# - 192.168.1.1
# - 192.168.1.2
# - 192.168.1.3
function shell_array_to_yaml_dash_list() {
  local arr=("$@")

  echo
  for i in "${!arr[@]}"; do
    echo -n "- ${arr[i]}"
    echo
  done
}
export -f shell_array_to_yaml_dash_list

# Todo, delete, renamed to wait_until_hostname_resolved
function wait_until_resolve_hostname() {
  local _host="$1"

  if valid_ipv4 "$_host"; then
    echo "Got ipv4 address, no need to resolve."
    return
  fi

  echo "$_host is not a valid ipv4 address, try to resolve it."
  while true; do
    if ! getent hosts "$_host" >/dev/null 2>&1; then
      echo "not yet resolved $_host, retry..." >&2
      sleep 2
    else
      ip=$(getent hosts "$_host" | head -n1 | awk '{print $1}')
      echo "resolved $_host to $ip" >&2
      echo $ip
      break
    fi
  done
}
export -f wait_until_resolve_hostname

function wait_until_hostname_resolved() {
  local _host="$1"

  if valid_ipv4 "$_host"; then
    echo "Got ipv4 address, no need to resolve."
    return
  fi

  echo "$_host is not a valid ipv4 address, try to resolve it."
  while true; do
    if ! getent hosts "$_host" >/dev/null 2>&1; then
      echo "not yet resolved $_host, retry..." >&2
      sleep 2
    else
      ip=$(getent hosts "$_host" | head -n1 | awk '{print $1}')
      echo "resolved $_host to $ip" >&2
      echo $ip
      break
    fi
  done
}
export -f wait_until_hostname_resolved

function wait_until_port_reached() {
  local _h=$1
  local _p=$2
  while true; do
    if nc -w 2 -z "${_h}" "${_p}"; then
      echo "wait completed ${_h}:${_p}"
      break
    else
      echo "still waiting ${_h}:${_p}"
      sleep 2
    fi
  done
}
export -f wait_until_port_reached

function is_number() {
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}
export -f is_number

function compare_version() {
  # the leading and trailing space/dot will be ignored. 1, .1, 1. are equal versions.
  # Given two versions, convert them into two arrays by splitting the version string by dot(.).
  # Recursively comparing elements of the same index from the two arrays until found inequality or loop end.
  # If the two elments are both pure numbers, compare them numerically, or else compare them lexicographically/alphanumerically
  # 8 and 008 are considered to be numerically equal.
  # 1.1 and 1.001 are considered to be equal versions.

  local _version1="${1:-0}"
  local _version2="${2:-0}"
  local _op="${3:-eq}"

  # operator(OP) is one of eq, ne, lt, le, gt, or ge,
  # if op is NOT a valid string, forcely set to 'eq'
  if ! [[ $_op == 'eq' || $_op == 'ne' || $_op == 'lt' || $_op == 'le' || $_op == 'gt' || $_op == 'ge' ]]; then
    $_op == 'eq'
  fi

  TRUE=0
  FALSE=1

  # the leading and trailing space/dot will be ignored by converting to array
  version1_array=(${_version1//./ })
  version2_array=(${_version2//./ })
  version2_array_len=${#version2_array[@]}

  for i in "${!version1_array[@]}"; do
    v1=${version1_array[i]}

    if [ $i -gt $((version2_array_len - 1)) ]; then
      [[ $_op == 'gt' || $_op == 'ge' || $_op == 'ne' ]] && return $TRUE || return $FALSE
    else
      v2=${version2_array[i]}

      if $(is_number "${v1}") && $(is_number "${v2}"); then
        if [ "$v1" -gt "$v2" ]; then # numeric greater
          [[ $_op == 'gt' || $_op == 'ge' || $_op == 'ne' ]] && return $TRUE || return $FALSE
        elif [[ "$v1" -lt "$v2" ]]; then # numeric lower
          [[ $_op == 'lt' || $_op == 'le' || $_op == 'ne' ]] && return $TRUE || return $FALSE
        else
          continue # numeric equal
        fi
      else
        if [[ "$v1" > "$v2" ]]; then # lexicographically greater
          [[ $_op == 'gt' || $_op == 'ge' || $_op == 'ne' ]] && return $TRUE || return $FALSE
        elif [[ "$v1" < "$v2" ]]; then # lexicographically lower
          [[ $_op == 'lt' || $_op == 'le' || $_op == 'ne' ]] && return $TRUE || return $FALSE
        else
          continue # lexicographically equal
        fi
      fi
    fi
  done

  # If the above for loop does not return, it means all subparts of the two versions are 'numeric equal' or 'lexicographically equal'.
  if [[ $_op == 'eq' || $_op == 'ge' || $_op == 'le' ]]; then
    return $TRUE
  fi

  return $FALSE

}
export -f compare_version

function download_file() {
  local _filepath=$1
  local _fileurl=$2

  if [[ -e "$_filepath" ]]; then
    zflag="-z $_filepath"
  else
    zflag=
  fi

  echo "Downloading file: $(basename $_filepath)"
  curl ${zflag} -o "$_filepath" "$_fileurl"
}
export -f download_file

function create_mysql_db_user_pass() {
  if [[ $# -lt 1 ]]; then
    echo "Error: Invalid parameters"
    cat <<EOF
Usage: $0 <db_user_pass_str> [<db_host> <db_port> <db_authuser> <db_authpass>]
The format of <db_user_pass_str> is: "<db1name>/<db1user>/<db1pass>[/<db1charset>/<db1collate>];<db2name>/<db2user>/<db2pass>[/<db2charset>/<db2collate>]"
When <db_user_pass_str> contains multiple parts separated by semicolon, it MUST be quoted.
If any of the <db_host>, <db_port>, <db_authuser>, <db_authpass> is omitted, its value will be retrieved from environment variables:
MYSQL_DB_HOST, MYSQL_DB_PORT, MYSQL_DB_AUTHUSER, MYSQL_DB_AUTHPASS.
EOF
    return 1
  fi

  if ! command -v mysql >/dev/null; then
    echo "Error: not found mysql command"
    return 1
  fi

  local db_user_pass_str="$1"
  local db_user_pass_array=(${db_user_pass_str//;/ })

  local db_host="${MYSQL_DB_HOST:-127.0.0.1}"
  local db_port="${MYSQL_DB_PORT:-3306}"
  local db_authuser="${MYSQL_DB_AUTHUSER:-root}"
  local db_authpass="${MYSQL_DB_AUTHPASS:-''}"

  [[ $# -ge 2 ]] && db_host="$2"
  [[ $# -ge 3 ]] && db_port="$3"
  [[ $# -ge 4 ]] && db_authuser="$4"
  [[ $# -ge 5 ]] && db_authpass="$5"

  local mysql_cmd="mysql -Ns -h${db_host} -P${db_port} -u${db_authuser} -p${db_authpass}"

  for i in ${db_user_pass_array[@]}; do
    db_user_pass=(${i//\// })
    if [[ ${#db_user_pass[@]} -lt 3 ]]; then
      echo "db_user_pass has wrong format ('dbname/dbuser/dbpass[/dbcharset/dbcollate][;dbname/dbuser/dbpass[/dbcharset/dbcollate]]')! Exit" && return 1
    fi
    _dbname=${db_user_pass[0]}
    _dbuser=${db_user_pass[1]}
    _dbpass=${db_user_pass[2]}

    # default value
    _dbcharset="utf8mb4"
    _dbcollate="utf8mb4_bin"

    if [[ ${#db_user_pass[@]} -ge 4 ]]; then
      _dbcharset=${db_user_pass[3]}
    fi

    if [[ ${#db_user_pass[@]} -ge 5 ]]; then
      _dbcollate=${db_user_pass[4]}
    fi

    echo "Create the following database/user/pass"
    echo "dbname: $_dbname"
    echo "dbuser: $_dbuser"
    echo "dbpass: $_dbpass"
    echo "dbcharset: $_dbcharset"
    echo "dbcollate: $_dbcollate"
    echo

    {
      cat <<EOSQL
CREATE DATABASE IF NOT EXISTS \`${_dbname}\` CHARACTER SET \`${_dbcharset}\` COLLATE \`${_dbcollate}\`;
GRANT ALL PRIVILEGES ON \`${_dbname}\`.* TO \`${_dbuser}\`@\`127.0.0.1\` IDENTIFIED WITH mysql_native_password BY "${_dbpass}";
GRANT ALL PRIVILEGES ON \`${_dbname}\`.* TO \`${_dbuser}\`@\`localhost\` IDENTIFIED WITH mysql_native_password BY "${_dbpass}";
GRANT ALL PRIVILEGES ON \`${_dbname}\`.* TO \`${_dbuser}\`@\`%\` IDENTIFIED WITH mysql_native_password BY "${_dbpass}";
FLUSH PRIVILEGES;
EOSQL

    } | $mysql_cmd

  done
}
export -f create_mysql_db_user_pass

function check_variables() {
  # helper function to make sure variables NOT EMPTY
  # usage: check_variables var1 var2 var3 ...
  for i in "$@"; do
    eval _value=\$${i}
    if [[ $_value == '' ]]; then
      echo "[X] $i must be set and not empty"
      exit 1
    else
      echo "[Y] $i: $_value"
    fi
  done
}
export -f check_variables

# If a line ends with a \, strip the backslash and print the line with no terminating newline;
# otherwise print the line with a terminating newline.
function combine_lines_backslash() {
  if [[ $# -ge 1 ]]; then
    # read from file, only use the first param, others are ignored
    local CONTENT="$(cat $1)"
  else
    # echo "Read content from stdin..."
    # echo "You can send your content through pipe, like: echo "something" | this_script"
    local CONTENT=$(</dev/stdin)
  fi

  echo "$CONTENT" | awk '{if (sub(/\\$/,"")) printf "%s", $0; else print $0}'
}
export -f combine_lines_backslash

###
###
### The following functions are mainly used inside docker containers.
###
###

function get_container_ip() {
  # scrape the first non-localhost IP address of the container
  # eg: in Docker Swarm Mode, we often get two IPs -- the container IP, and the (shared) VIP, and the container IP should always be first
  ip address | awk '
    $1 == "inet" && $NF != "lo" {
      gsub(/\/.+$/, "", $2)
      print $2
      exit
    }
  '
}
export -f get_container_ip

function get_k8s_pod_self_info() {
  # used inside the pod
  local KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
  local KUBE_NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
  local KUBE_CACERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

  curl -sS --cacert "$KUBE_CACERT" -H "Authorization: Bearer $KUBE_TOKEN" https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$KUBE_NAMESPACE/pods/$HOSTNAME
}
export -f get_k8s_pod_self_info

function get_k8s_statefulset_pod_replicas() {
  # used inside the pod
  # a statefulset pod can get the replicas of the statefulset, and then use the number to do something
  local KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
  local KUBE_NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
  local KUBE_CACERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

  # Note, the -e option of jq can set the exit status of jq
  # We use it to determine whether the subdomain field exists.
  if get_k8s_pod_self_info | jq -e -r .spec.subdomain >/dev/null 2>&1; then
    local pod_subdomain=$(get_k8s_pod_self_info | jq -e -r .spec.subdomain)

    local stateful_replicas=$(curl -sS --cacert "$KUBE_CACERT" -H "Authorization: Bearer $KUBE_TOKEN" https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$KUBE_NAMESPACE/endpoints/$pod_subdomain | jq -r '.subsets[0].addresses | length')

    if is_number $stateful_replicas; then
      echo $stateful_replicas
      return 0
    fi
  fi

  # If the function goes here, it means it can not derive a proper replicas number.
  echo "UNKNOWN"
  return 1
}
export -f get_k8s_statefulset_pod_replicas

#
# get_pod_* functions
# These functions can be called in containers regardless the underlying container platform (K8S, Swarm, ...)
# or pod type (deployment, statefulset, ...)
#

# Note: pod_name is not Pod Hostname
# eg: for statefulset pods, hostname is "zookeeper-0", here the pod_name is "zookeeper"
# the usage of pod_name is for automatically constructing other pods name like "zookeeper-1" inside the pod.
function get_pod_name() {
  # 1. If POD_NAME is set and not emtpy, use it.
  # 2. Try to auto derive pod name
  # 3. default hostname

  local _host=$(hostname -s)

  if [[ -n "${POD_NAME:+1}" ]]; then
    echo "${POD_NAME}"
  else
    if [[ $_host =~ (.*)-([0-9]+)$ ]]; then
      local _name=${BASH_REMATCH[1]}
      echo "$_name"
    else
      echo "$(hostname)"
    fi
  fi
}
export -f get_pod_name

function get_pod_domain() {
  # 1. Try to auto derive pod domain
  # 2. default empty
  local _domain=''

  if hostname -d >/dev/null 2>&1; then
    _domain=$(hostname -d)
  fi

  echo $_domain
}
export -f get_pod_domain

function get_pod_fqdn() {
  local _domain="$(get_pod_domain)"

  if [[ "X${_domain}" != "X" ]]; then
    echo "$(hostname).${_domain}"
  else
    echo "$(hostname)"
  fi
}
export -f get_pod_fqdn

function get_pod_ordinal() {
  # 1. If POD_ORDINAL is set, then it must be set to a valid number or else failed.
  # 2. Try to auto derive pod ordinal
  # 3. default 0
  local _host=$(hostname -s)

  if [[ -n "${POD_ORDINAL:+1}" ]]; then
    if is_number ${POD_ORDINAL}; then
      echo "${POD_ORDINAL}"
    else
      echo "The POD_ORDINAL must be a valid number."
      exit 1
    fi
  else
    if [[ $_host =~ (.*)-([0-9]+)$ ]]; then
      local _ordinal=${BASH_REMATCH[2]} # ordinal
      echo "$_ordinal"
    else
      echo 0
    fi
  fi
}
export get_pod_ordinal

function get_pod_replicas() {
  # 1. If POD_REPLICAS is set, then it must be set to a valid number or else failed.
  # 2. Try to auto derive pod replicas
  # 3. default 1
  if [[ -n "${POD_REPLICAS:+1}" ]]; then
    if is_number ${POD_REPLICAS}; then
      echo "${POD_REPLICAS}"
    else
      echo "The POD_REPLICAS must be a valid number."
      exit 1
    fi
  elif get_k8s_statefulset_pod_replicas >/dev/null 2>&1; then
    echo "$(get_k8s_statefulset_pod_replicas)"
  else
    echo 1
  fi
}
export -f get_pod_replicas

function update_config() {
  key=$1
  value=$2
  file=$3
  sep=$4

  # Omit $value here, in case there is sensitive information
  echo "[Configuring] '$key' in '$file'"

  if [[ $sep == ":" ]]; then
    if grep -E -q "^$key$sep" "$file"; then
      sed -r -i "s@^$key$sep.*@$key$sep $value@g" "$file" #note that no config values may contain an '@' char
    else
      echo "$key$sep $value" >>"$file"
    fi
  elif [[ $sep == "=" ]]; then
    crudini --set "$file" '' "$key" "$value"
  else
    echo "Unknown separator, ignore"
  fi
}
export -f update_config

# Todo, merge into above update_config function
# kong.conf does not fully compatible with crudini tool
function mod_file() {
  local _file=$1
  local _option=$2
  local _value=$3

  if $(cat $_file | grep -sq "^$_option ="); then
    sed -i "s|\($_option =\).*|\1 $_value|g" $_file
  else
    echo "$_option = $_value" >>$_file
  fi
}
export -f mod_file
