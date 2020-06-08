#!/bin/bash

export _style_no="\033[0m"            # no color

export _style_red="\033[0;31m"
export _style_blue="\033[1;34m"
export _style_green="\033[0;32m"

# normal
export _style_black="\033[0;30m"
export _style_red="\033[0;31m"
export _style_green="\033[0;32m"
export _style_orange="\033[0;33m" # 棕黄
export _style_blue="\033[0;34m"
export _style_purple="\033[0;35m"
export _style_cyan="\033[0;36m"   # 青
export _style_light_gray="\033[0;37m"

# bold
export _style_dark_gray="\033[1;30m"
export _style_bold_red="\033[1;31m"
export _style_bold_green="\033[1;32m"
export _style_bold_orange="\033[1;33m"
export _style_bold_blue="\033[1;34m"
export _style_bold_purple="\033[1;35m"
export _style_bold_cyan="\033[1;36m"   # 青
export _style_bold_gray="\033[1;37m"


export _style_info="\033[30m"         # gray
export _style_ok="\033[42m"           # green
export _style_warn="\033[43m"         # yellow
export _style_error="\033[41m"        # red

export _style_highlight="\033[46m"    # blue
export _style_explanation="\033[34m"  # explanation
export _style_bold="\033[1m"          # bold


# style_echo red "hello\nworld"
function style_echo() {
  local color=$(eval echo \$$"_style_$1")
  local content="$2"
  echo -e "${color}${content}${_style_no}"
}
export -f style_echo


function echo_info() {
  style_echo info "$*"
}
export -f echo_info

function echo_warn() {
  style_echo warn "$*"
}
export -f echo_warn

function echo_error() {
  style_echo error "$*"
}
export -f echo_error

function echo_ok() {
  style_echo ok "$*"
}
export -f echo_ok

function echo_highlight() {
  style_echo highlight "$*"
}
export -f echo_highlight

# Macos `date` does not recognize %N, use `gdate` on MacOS

log() {
  echo "$(date +'%F %T.%3N') | $(echo_info INFO) | $*"
}
export -f log

log_info() {
  echo "$(date +'%F %T.%3N') | $(echo_info INFO) | $*"
}
export -f log_info

log_warn() {
  echo "$(date +'%F %T.%3N') | $(echo_warn WARN) | $*"
}
export -f log_warn

log_err() {
  echo "$(date +'%F %T.%3N') | $(echo_error ERROR) | $*"
}
export -f log_err



underline() { printf "${underline}${bold}%s${reset}\n" "$@"
}
h1() { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@"
}
h2() { printf "\n${underline}${bold}${white}%s${reset}\n" "$@"
}
debug() { printf "${white}%s${reset}\n" "$@"
}
info() { printf "${white}➜ %s${reset}\n" "$@"
}
success() { printf "${green}✔ %s${reset}\n" "$@"
}
error() { printf "${red}✖ %s${reset}\n" "$@"
}
warn() { printf "${tan}➜ %s${reset}\n" "$@"
}
bold() { printf "${bold}%s${reset}\n" "$@"
}
note() { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@"
}
