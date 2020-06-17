#!/bin/bash

function a.docker.ct_pid() {
  # You pass multiple container identifiers
  docker inspect --format '{{.State.Pid}}' "$@"
}
export -f a.docker.ct_pid

function a.docker.ct_ip() {
  docker inspect --format '{{.NetworkSettings.IPAddress}}' "$@"
}
export -f a.docker.ct_ip

function a.docker.ct_enter() {
  # equivalent to docker exec

  local ct_name=$1
  # Get the pid of the first process in the container.
  local ct_pid=$(docker inspect -f {{.State.Pid}} $ct_name)

  nsenter --target $ct_pid --mount --uts --ipc --net --pid
}
export -f a.docker.ct_enter
