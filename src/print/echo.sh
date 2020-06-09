#!/bin/bash

export _style_no="\033[0m"            # no color

# https://misc.flogisoft.com/bash/tip_colors_and_formatting
declare -A fontStyle=(
  ["normal"]="0"          # 正常
  ["bold"]="1"            # 粗体
  ["dim"]="2"             # 暗淡
  ["underline"]="4"       # 下划线
  ["blink"]="5"           # 闪烁
  ["strikethrough"]="6"   # 删除线
  ["invert"]="7"          # 反相
  ["hidden"]="8"          # 隐藏
)

declare -A fontColor=(
  ["default"]="39"
  ["black"]="30"
  ["red"]="31"
  ["green"]="32"
  ["yellow"]="33"
  ["blue"]="34"
  ["magenta"]="35"    # 洋红
  ["cyan"]="36"       # 蓝绿
  ["lightgray"]="37"
  ["darkgray"]="90"
  ["lightred"]="91"
  ["lightgreen"]="92"
  ["lightyellow"]="93"
  ["lightblue"]="94"
  ["lightmagenta"]="95"
  ["lightcyan"]="96"
  ["white"]="97"
)

declare -A backgroundColor=(
  ["default"]="49"
  ["black"]="40"
  ["red"]="41"
  ["green"]="42"
  ["yellow"]="43"
  ["blue"]="44"
  ["magenta"]="45"
  ["cyan"]="46"
  ["lightgray"]="47"
  ["darkgray"]="100"
  ["lightred"]="101"
  ["lightgreen"]="102"
  ["lightyellow"]="103"
  ["lightblue"]="104"
  ["lightmagenta"]="105"
  ["lightcyan"]="106"
  ["white"]="107"
)

for fs in ${!fontStyle[@]}; do
  for fc in ${!fontColor[@]}; do
    for bc in ${!backgroundColor[@]}; do
      export "_style_${fs}_${fc}_${bc}=\033[${fontStyle[$fs]};${fontColor[$fc]};${backgroundColor[$bc]}m"
    done
  done
done



export _style_info="$_style_bold_gray_default"
export _style_ok="$_style_bold_green_default"
export _style_warn="$_style_bold_yellow_default"
export _style_error="$_style_bold_red_default"


# style_echo red "hello\nworld"
function style_echo() {
  local color=$(eval echo \$$"_style_$1")
  shift 1
  local content="$@"
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
