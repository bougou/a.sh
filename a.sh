#!/bin/bash

alias a.net.tcp_state_sum='ss -ant | tail -n+2 | awk '\''{print $1}'\''| sort | uniq -c | sort -n'

function a.net.valid_ipv4() {
  local ip=$1
  local stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
        && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    stat=$?
  fi
  return $stat
}
export -f a.net.valid_ipv4


function a.net.wait_until_resolve_hostname() {
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
            ip=`getent hosts "$_host" | head -n1 | awk '{print $1}'`
            echo "resolved $_host to $ip" >&2
            echo $ip
            break
        fi
    done
}
export -f a.net.wait_until_resolve_hostname


function a.net.wait_until_hostname_resolved() {
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
            ip=`getent hosts "$_host" | head -n1 | awk '{print $1}'`
            echo "resolved $_host to $ip" >&2
            echo $ip
            break
        fi
    done
}
export -f a.net.wait_until_hostname_resolved

function a.net.wait_until_port_reached() {
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
export -f a.net.wait_until_port_reached

function a.net.get_inf_ip() {
  # Get ip address of the specified interface.
  local _inf=$1
  local _ipaddr=$(ip address show $_inf | grep 'inet' | awk '{print $2}' | awk -F/ '{print $1}' | head -n1)
  echo $_ipaddr
}
export -f a.net.get_inf_ip


function a.net.check_inf_ip() {
  # Check whether the specified interface has the specified ip address.
  local _inf=$1
  local _ipaddr=$2
  ip address show $_inf | grep 'inet ' | awk '{print $2}' | awk -F/ '{print $1}' | grep -sq $_ipaddr
}
export -f a.net.check_inf_ip


function a.net.add_inf_ip() {
  # Add the specified ip address to the specified interface.
  local _inf=$1
  local _ipaddr=$2
  ip address add $_ipaddr dev $_inf
  arping -I $_inf -c 3 -U $_ipaddr
}
export -f a.net.add_inf_ip


function a.net.check_configure_inf_ip() {
  local _inf=$1
  local _ipaddr=$2
  if check_inf_ip $_inf $_ipaddr; then
    echo_ok "$_ipaddr is configured on $_inf"
    return 0
  else
    echo_warn "Not found $_ipaddr on $_inf, configuring it ..."
    add_inf_ip $_inf $_ipaddr
  fi

  # recheck
  if check_inf_ip $_inf $_ipaddr; then
    echo_ok "$_ipaddr is configured on $_inf"
    return 0
  else
    echo_err "Error: can't correctly configured $_ipaddr on $_inf"
    return 1
  fi
}
export -f a.net.check_configure_inf_ip
function a.net.ovs_bind_br_if() {
  ##If the interface has ip, then the ip will be configured on the ovs bridge.

  ovs_br=$1
  br_if=$2

  ip link show $br_if
  [[ $? -ne 0 ]] && echo "Error: $br_if NOT exist, exit" && return 1

  ovs-vsctl list-ports $ovs_br | grep -sq $br_if
  [[ $? -eq 0 ]] && echo "$br_if already is port of $ovs_br, nothing to do, exit" && return 0

  # if_mac=$(nmcli dev show $br_if | grep -F 'GENERAL.HWADDR' | awk '{print $2}')
  br_ip=$(nmcli dev show $br_if | grep -F 'IP4.ADDRESS[1]' | awk '{print $2}' | awk -F/ '{print $1}')
  if [[ X"$br_ip" != 'X' ]]; then
    br_prefix=$(nmcli dev show $br_if | grep -F 'IP4.ADDRESS[1]' | awk '{print $2}' | awk -F/ '{print $2}')
    br_gw=$(nmcli dev show $br_if | grep -F 'IP4.GATEWAY' | awk '{print $2}')
    br_dns1=$(nmcli dev show $br_if | grep -F 'IP4.DNS[1]'| awk '{print $2}')
    br_dns2=$(nmcli dev show $br_if | grep -F 'IP4.DNS[2]'| awk '{print $2}')
  fi

  cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-$ovs_br
DEVICE=$ovs_br
DEVICETYPE=ovs
TYPE=OVSBridge
ONBOOT=yes
BOOTPROTO=static
IPADDR=$br_ip
PREFIX=$br_prefix
GATEWAY=$br_gw
DNS1=$br_dns1
DNS2=$br_dns2
EOF


  cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-$br_if
DEVICE=$br_if
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=$ovs_br
ONBOOT=yes
BOOTPROTO=none
EOF

  if grep -sq '^NOZEROCONF=' /etc/sysconfig/network; then
    sed -i '/^NOZEROCONF=/c\NOZEROCONF=yes' /etc/sysconfig/network
  else
    echo 'NOZEROCONF=yes' >> /etc/sysconfig/network
  fi

  ## add-port must be executed afther systemctl restart network.
  ovs-vsctl add-br $ovs_br
  ovs-vsctl add-port $ovs_br $br_if

  ip addr add $br_ip/$br_prefix dev $ovs_br
  ip link set dev $ovs_br up

}
export -f a.net.ovs_bind_br_if


function a.net.run_over_ssh() {
  # run command over ssh
  local host="$1"
  shift
  ssh ${SSH_OPTS} -t "${host}" "$@" >/dev/null 2>&1
}
export -f a.net.run_over_ssh


function a.net.run_over_scp() {
  # copy file recursively over ssh
  local host="$1"
  local src=($2)
  local dst="$3"
  scp -r ${SSH_OPTS} ${src[*]} "${host}:${dst}"
}
export -f a.net.run_over_scp


function a.util.is_number() {
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}
export -f a.util.is_number


function a.util.compare_version() {
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

        if [ $i -gt $(( version2_array_len - 1 )) ]; then
            [[ $_op == 'gt' || $_op == 'ge' || $_op == 'ne' ]] && return $TRUE || return $FALSE
        else
            v2=${version2_array[i]}

            if `a.util.is_number "${v1}"` && `a.util.is_number "${v2}"`; then
                if [ "$v1" -gt "$v2" ]; then # numeric greater
                    [[ $_op == 'gt' || $_op == 'ge' || $_op == 'ne' ]] && return $TRUE || return $FALSE
                elif [[ "$v1" -lt "$v2" ]]; then # numeric lower
                    [[ $_op == 'lt' || $_op == 'le' || $_op == 'ne' ]] && return $TRUE || return $FALSE
                else
                    continue # numeric equal
                fi
            else
                if [[ "$v1" > "$v2" ]]; then  # lexicographically greater
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
export -f a.util.compare_version


function a.util.download_file() {
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
export -f a.util.download_file



function a.util.check_variables() {
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
export -f a.util.check_variables

function a.util.command_existed() {
  # check whether a command exists
  command -v "$1" >/dev/null 2>&1
}
export -f a.util.command_existed

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


function a.util.shell_array_to_yaml_dash_list() {
  local arr=("$@")

  echo
  for i in "${!arr[@]}"; do
    echo -n "- ${arr[i]}"
    echo
  done
}
export -f a.util.shell_array_to_yaml_dash_list

function a.file.combine_lines_backslash() {
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
export -f a.file.combine_lines_backslash


function a.config.update_config() {
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
      echo "$key$sep $value" >> "$file"
    fi
  elif [[ $sep == "=" ]]; then
    crudini --set "$file" '' "$key" "$value"
  else
    echo "Unknown separator, ignore"
  fi
}
export -f a.config.update_config


function a.config.mod_file() {
  local _file=$1
  local _option=$2
  local _value=$3

  if `cat $_file | grep -sq "^$_option ="`; then
    sed -i "s|\($_option =\).*|\1 $_value|g" $_file
  else
    echo "$_option = $_value" >> $_file
  fi
}
export -f a.config.mod_file


function a.k8s.get_container_ip() {
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
export -f a.k8s.get_container_ip


function a.k8s.get_k8s_pod_self_info() {
  # used inside the pod
  local KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
  local KUBE_NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
  local KUBE_CACERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

  curl -sS --cacert "$KUBE_CACERT" -H "Authorization: Bearer $KUBE_TOKEN" https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$KUBE_NAMESPACE/pods/$HOSTNAME
}
export -f a.k8s.get_k8s_pod_self_info


function a.k8s.get_k8s_statefulset_pod_replicas() {
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

    if a.util.is_number $stateful_replicas; then
      echo $stateful_replicas
      return 0
    fi
  fi

  # If the function goes here, it means it can not derive a proper replicas number.
  echo "UNKNOWN"
  return 1
}
export -f a.k8s.get_k8s_statefulset_pod_replicas




function a.k8s.get_pod_name() {
  # 1. If POD_NAME is set and not emtpy, use it.
  # 2. Try to auto derive pod name
  # 3. default hostname

  local _host=`hostname -s`

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
export -f a.k8s.get_pod_name


function a.k8s.get_pod_domain() {
  # 1. Try to auto derive pod domain
  # 2. default empty
  local _domain=''

  if hostname -d >/dev/null 2>&1; then
    _domain=`hostname -d`
  fi

  echo $_domain
}
export -f a.k8s.get_pod_domain


function a.k8s.get_pod_fqdn() {
  local _domain="$(get_pod_domain)"

  if [[ "X${_domain}" != "X" ]]; then
    echo "$(hostname).${_domain}"
  else
    echo "$(hostname)"
  fi
}
export -f a.k8s.get_pod_fqdn


function a.k8s.get_pod_ordinal() {
  # 1. If POD_ORDINAL is set, then it must be set to a valid number or else failed.
  # 2. Try to auto derive pod ordinal
  # 3. default 0
  local _host=`hostname -s`

  if [[ -n "${POD_ORDINAL:+1}" ]]; then
    if a.util.is_number ${POD_ORDINAL}; then
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
export -f a.k8s.get_pod_ordinal


function a.k8s.get_pod_replicas() {
  # 1. If POD_REPLICAS is set, then it must be set to a valid number or else failed.
  # 2. Try to auto derive pod replicas
  # 3. default 1
  if [[ -n "${POD_REPLICAS:+1}" ]]; then
    if a.util.is_number ${POD_REPLICAS}; then
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
export -f a.k8s.get_pod_replicas

function info_print() {
  msg=$1
  printf "%-60s  " "$msg"
}
export -f info_print

export c_no="\e[0m"

export c_ok="\e[42m"

export c_warn="\e[43m"

export c_err="\e[41m"


export c_hl="\e[46m"

export c_exp="\e[34m"

export c_bold="\e[1m"


function echo_warn() { echo -e "${c_warn}$1${c_no}"; } && export -f echo_warn
function echo_err() { echo -e "${c_err}$1${c_no}"; } && export -f echo_err
function echo_ok() { echo -e "${c_ok}$1${c_no}"; } && export -f echo_ok

function echo_hl() { echo -e "${c_hl}$1${c_no}"; } && export -f echo_hl
function echo_exp() { echo -e "${c_exp}$1${c_no}"; } && export -f echo_exp

function a.db.create_mysql_db_user_pass() {
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
export -f a.db.create_mysql_db_user_pass

function a.pkg.rpm_yum_install() {
  # yum install a list of packages and omit already installed packages.
  local _not_installed_pkgs=""
  for _pkg in $@; do
    rpm -qi --quiet $_pkg || _not_installed_pkgs="$_not_installed_pkgs $_pkg"
  done
  [[ "X$_not_installed_pkgs" != "X" ]] && yum install -y $_not_installed_pkgs || :
}
export -f a.pkg.rpm_yum_install


function a.pkg.rpm_package_installed() {
  # determine whether a rpm package is installed
  rpm -qa | grep -sq $1
}
export -f a.pkg.rpm_package_installed
