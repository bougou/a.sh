#!/bin/bash

# Steal from kubernetes source code.

function a.net.run-over-ssh() {
  # run command over ssh
  local host="$1"
  shift
  ssh ${SSH_OPTS} -t "${host}" "$@" >/dev/null 2>&1
}
export -f a.net.run-over-ssh


function a.net.run-over-scp() {
  # copy file recursively over ssh
  local host="$1"
  local src=($2)
  local dst="$3"
  scp -r ${SSH_OPTS} ${src[*]} "${host}:${dst}"
}
export -f a.net.run-over-scp
