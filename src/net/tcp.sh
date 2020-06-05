#!/bin/bash

alias a.net.tcp_state_sum='ss -ant | tail -n+2 | awk '\''{print $1}'\''| sort | uniq -c | sort -n'
