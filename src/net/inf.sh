
function a.net.get_inf_ip() {
  # Get ip address of the specified interface.
  local _inf=$1
  local _ipaddr=$(ip address show $_inf | grep 'inet' | awk '{print $2}' | awk -F/ '{print $1}' | head -n1)
  echo $_ipaddr
}
export -f a.net.get_inf_ip


function a.net.check_inf_ip() {
  # Check whether the specified interface has the specified ip address.
  local _inf=$1
  local _ipaddr=$2
  ip address show $_inf | grep 'inet ' | awk '{print $2}' | awk -F/ '{print $1}' | grep -sq $_ipaddr
}
export -f a.net.check_inf_ip


function a.net.add_inf_ip() {
  # Add the specified ip address to the specified interface.
  local _inf=$1
  local _ipaddr=$2
  ip address add $_ipaddr dev $_inf
  arping -I $_inf -c 3 -U $_ipaddr
}
export -f a.net.add_inf_ip


function a.net.check_configure_inf_ip() {
  local _inf=$1
  local _ipaddr=$2
  if check_inf_ip $_inf $_ipaddr; then
    echo_ok "$_ipaddr is configured on $_inf"
    return 0
  else
    echo_warn "Not found $_ipaddr on $_inf, configuring it ..."
    add_inf_ip $_inf $_ipaddr
  fi

  # recheck
  if check_inf_ip $_inf $_ipaddr; then
    echo_ok "$_ipaddr is configured on $_inf"
    return 0
  else
    echo_err "Error: can't correctly configured $_ipaddr on $_inf"
    return 1
  fi
}
export -f a.net.check_configure_inf_ip
