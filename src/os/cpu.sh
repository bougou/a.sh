#!/bin/bash

function a.os.show_cpu_numbers() {
  cpus_physical=`cat /proc/cpuinfo | grep -i "physical id" | sort | uniq -c | wc -l`
  cores_per_cpu=`cat  /proc/cpuinfo | grep "cpu cores" | sort | uniq | awk -F: '{print $2}'`
  cores_all=$(( cores_per_cpu * cpus_physical ))
  cpus_logical=`cat /proc/cpuinfo | grep "processor" | wc -l`

  # Desc of Fields in File /proc/cpuinfo
  # processor:    ID of logical CPU.
  # physcial id:  ID of physcial CPU where the logical CPU resides.
  # siblings:     Total logical CPUs of the physical CPU where the logical CPU resides.
  # cpu cores:　  Total physical Cores of the physcial CPU where the logical CPU resides.

  printf "%-40s%-10s\n" "Total physical CPUs:" $cpus_physical
  printf "%-40s%-10s\n" "Cores per physical CPU:" $cores_per_cpu
  printf "%-40s%-10s\n" "Total cores:" "$cores_all"
  printf "%-40s%-10s\n" "Total logical CPUs:" "$cpus_logical"

  if [[ $cpus_logical -eq $cores_all ]]; then
      printf "%-40s%-10s\n" "Hyper Thread (HT):" "Not Enabled"
  fi

}
export -f a.os.show_cpu_numbers

function a.os.show_cpu_usage_of_pid() {
  uptime=$(cat /proc/uptime | awk '{print $1}')
  idletime=$(cat /proc/uptime | awk '{print $2}')

  p_name=$(cat /proc/$PID/stat | awk '{print $2}')

  p_utime_j=$(cat /proc/$PID/stat | awk '{print $14}')
  p_utime=$(echo "scale=2;$p_utime_j/100" | bc)

  p_stime_j=$(cat /proc/$PID/stat | awk '{print $15}')
  p_stime=$(echo "scale=2;$p_stime_j/100" | bc)

  p_cutime_j=$(cat /proc/$PID/stat | awk '{print $16}')
  p_cutime=$(echo "scale=2;$p_cutime_j/100" | bc)

  p_cstime_j=$(cat /proc/$PID/stat | awk '{print $17}')
  p_cstime=$(echo "scale=2;$p_cstime_j/100" | bc)

  p_starttime_j=$(cat /proc/$PID/stat | awk '{print $22}')
  p_starttime=$(echo "scale=2;$p_starttime_j/100" | bc)

  p_cputime_j=$(( p_utime_j + p_stime_j ))
  p_cputime=$(echo "scale=2;$p_cputime_j/100" | bc)

  p_runtime=$(echo "$uptime-$p_starttime" | bc)

  p_cpu_percent=$(echo "scale=2;$p_cputime*100/$p_runtime" | bc)

  echo "System information"
  printf "%20s : %s seconds\n" "uptime" $uptime
  printf "%20s : %s seconds\n" "idle" $idletime

  echo
  echo "Process information"
  printf "%20s : %s\n" "PID" $PID
  printf "%20s : %s\n" "filename" $p_name
  printf "%20s : %s jiffies %s seconds\n" "utime" $p_utime_j $p_utime
  printf "%20s : %s jiffies %s seconds\n" "stime" $p_stime_j $p_stime
  printf "%20s : %s jiffies %s seconds\n" "cutime" $p_cutime_j $p_cutime
  printf "%20s : %s jiffies %s seconds\n" "cstime" $p_cstime_j $p_cstime
  printf "%20s : %s jiffies %s seconds\n" "starttime" $p_starttime_j $p_starttime

  echo
  printf "%20s : %s seconds\n" "Process run time" $p_runtime
  printf "%20s : %s seconds\n" "Process CPU time" $p_cputime
  printf "CPU Usage since birth: %s%%\n" $p_cpu_percent

}
export -f a.os.show_cpu_usage_of_pid
