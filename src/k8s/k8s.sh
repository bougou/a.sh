#!/bin/bash

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
export -f get_pod_name


function get_pod_domain() {
  # 1. Try to auto derive pod domain
  # 2. default empty
  local _domain=''

  if hostname -d >/dev/null 2>&1; then
    _domain=`hostname -d`
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
  local _host=`hostname -s`

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
