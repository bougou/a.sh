#!/bin/bash

export c_no="\e[0m"

# ok: Green
export c_ok="\e[42m"

# warn: Yellow
export c_warn="\e[43m"

# error: Red
export c_err="\e[41m"


# highlight: Blue
export c_hl="\e[46m"

# explanation:
export c_exp="\e[34m"

# Blod
export c_bold="\e[1m"


function echo_warn() { echo -e "${c_warn}$1${c_no}"; } && export -f echo_warn
function echo_err() { echo -e "${c_err}$1${c_no}"; } && export -f echo_err
function echo_ok() { echo -e "${c_ok}$1${c_no}"; } && export -f echo_ok

function echo_hl() { echo -e "${c_hl}$1${c_no}"; } && export -f echo_hl
function echo_exp() { echo -e "${c_exp}$1${c_no}"; } && export -f echo_exp
