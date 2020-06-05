function a.net.ovs_bind_br_if() {
  ##If the interface has ip, then the ip will be configured on the ovs bridge.

  ovs_br=$1
  br_if=$2

  ip link show $br_if
  [[ $? -ne 0 ]] && echo "Error: $br_if NOT exist, exit" && return 1

  ovs-vsctl list-ports $ovs_br | grep -sq $br_if
  [[ $? -eq 0 ]] && echo "$br_if already is port of $ovs_br, nothing to do, exit" && return 0

  # if_mac=$(nmcli dev show $br_if | grep -F 'GENERAL.HWADDR' | awk '{print $2}')
  br_ip=$(nmcli dev show $br_if | grep -F 'IP4.ADDRESS[1]' | awk '{print $2}' | awk -F/ '{print $1}')
  if [[ X"$br_ip" != 'X' ]]; then
    br_prefix=$(nmcli dev show $br_if | grep -F 'IP4.ADDRESS[1]' | awk '{print $2}' | awk -F/ '{print $2}')
    br_gw=$(nmcli dev show $br_if | grep -F 'IP4.GATEWAY' | awk '{print $2}')
    br_dns1=$(nmcli dev show $br_if | grep -F 'IP4.DNS[1]'| awk '{print $2}')
    br_dns2=$(nmcli dev show $br_if | grep -F 'IP4.DNS[2]'| awk '{print $2}')
  fi

  cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-$ovs_br
DEVICE=$ovs_br
DEVICETYPE=ovs
TYPE=OVSBridge
ONBOOT=yes
BOOTPROTO=static
IPADDR=$br_ip
PREFIX=$br_prefix
GATEWAY=$br_gw
DNS1=$br_dns1
DNS2=$br_dns2
EOF

## Do not modify interface's original configuration.
## Thus, be caution to execute systemctl restart network, because of ovs port information will be lost.
## ovs-vsctl add-port

  cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-$br_if
DEVICE=$br_if
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=$ovs_br
ONBOOT=yes
BOOTPROTO=none
EOF

  if grep -sq '^NOZEROCONF=' /etc/sysconfig/network; then
    sed -i '/^NOZEROCONF=/c\NOZEROCONF=yes' /etc/sysconfig/network
  else
    echo 'NOZEROCONF=yes' >> /etc/sysconfig/network
  fi

  ## add-port must be executed afther systemctl restart network.
  ovs-vsctl add-br $ovs_br
  ovs-vsctl add-port $ovs_br $br_if

  ip addr add $br_ip/$br_prefix dev $ovs_br
  ip link set dev $ovs_br up

}
export -f a.net.ovs_bind_br_if
