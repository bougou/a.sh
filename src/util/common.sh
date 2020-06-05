#!/bin/bash

function command_existed() {
  # check whether a command exists
  command -v "$1" >/dev/null 2>&1
}
export -f command_existed
