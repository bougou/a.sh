#!/bin/bash

alias a.net.tcp_state_sum='ss -ant | tail -n+2 | awk '\''{print $1}'\''| sort | uniq -c | sort -n'

function a.net.show_tcp_state() {
  # netstat -an | awk '/^tcp/{++state[$NF]} END{for(key in state) print key,"\t",state[key]}'
  ss -at -n | sed '1d' | awk '{++state[$1]} END{for(key in state) print key,"\t",state[key]}' | column -t
}
export -f a.net.show_tcp_state
