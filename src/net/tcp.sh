alias a.net.tcp_state_sum='ss -ant | tail -n+2 | awk '\''{print $1}'\''| sort | uniq -c | sort -n'

function a.net.show_tcp_state() {
  # netstat -an | awk '/^tcp/{++state[$NF]} END{for(key in state) print key,"\t",state[key]}'
  ss -at -n | sed '1d' | awk '{++state[$1]} END{for(key in state) print key,"\t",state[key]}' | column -t
}
export -f a.net.show_tcp_state

a.net.show_tcp_port_source_num() {
  local port=$1

  regpattern=":$port\$"

  netstat -tan |
    awk -v r=$regpattern '$4 ~ r' |
    awk '{print $5}' |
    awk -F: '{print $1}' |
    grep -v '^$' |
    sort | uniq -c

  #| awk '$1>100{print $1, $2}'
}
export -f a.net.show_tcp_port_source_num
