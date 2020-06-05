#!/bin/bash

function rpm_yum_install() {
  # yum install a list of packages and omit already installed packages.
  local _not_installed_pkgs=""
  for _pkg in $@; do
    rpm -qi --quiet $_pkg || _not_installed_pkgs="$_not_installed_pkgs $_pkg"
  done
  [[ "X$_not_installed_pkgs" != "X" ]] && yum install -y $_not_installed_pkgs || :
}
export -f rpm_yum_install


function rpm_package_installed() {
  # determine whether a rpm package is installed
  rpm -qa | grep -sq $1
}
export -f package_installed
