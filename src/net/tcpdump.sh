function a.net.tcpdump_http() {
  # see: https://serverfault.com/questions/504431/human-readable-format-for-http-headers-with-tcpdump

  local http_port=$1

  stdbuf -oL -eL $(which tcpdump) -A -s 10240 "tcp port ${http_port} and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)" | egrep --line-buffered "^........(GET |HTTP\/|POST |HEAD )|^[A-Za-z0-9-]+: " | sed -r 's/^........(GET |HTTP\/|POST |HEAD )/\n\1/g'

}
export a.net.tcpdump_http
