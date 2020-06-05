#!/bin/bash

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


# Todo, delete, renamed to wait_until_hostname_resolved
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
