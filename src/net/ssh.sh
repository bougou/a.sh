#!/bin/bash

# Steal from kubernetes source code.

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
