function a.os.dmi_info() {

  cat <<EOF | xargs -I {} sh -c 'printf "%30s: " {}; dmidecode -s {} | head -n1; echo' | sed '/^$/d'
  bios-vendor
  bios-version
  bios-release-date
  system-manufacturer
  system-product-name
  system-version
  system-serial-number
  system-uuid
  baseboard-manufacturer
  baseboard-product-name
  baseboard-version
  baseboard-serial-number
  baseboard-asset-tag
  chassis-manufacturer
  chassis-type
  chassis-version
  chassis-serial-number
  chassis-asset-tag
  processor-family
  processor-manufacturer
  processor-version
  processor-frequency
EOF

}
export -f a.os.dmi_info

function a.os.dmi_info2() {

  echo "
bios-vendor
bios-version
bios-release-date
system-manufacturer
system-product-name
system-version
system-serial-number
system-uuid
baseboard-manufacturer
baseboard-product-name
baseboard-version
baseboard-serial-number
baseboard-asset-tag
chassis-manufacturer
chassis-type
chassis-version
chassis-serial-number
chassis-asset-tag
processor-family
processor-manufacturer
processor-version
processor-frequency
" | while read cmd; do
    [[ -z $cmd ]] && continue
    printf "%-25s: " $cmd
    OLD_IFS=$IFS
    IFS=$(echo -en "\n\b")
    res=$(dmidecode -s $cmd)
    [[ -z $res ]] && echo '[none]' && continue
    i=1
    for r in $res; do
      if [[ $i -eq 1 ]]; then
        printf "%s\n" $r
      else
        printf " %.0s" {1..27}
        printf "%s\n" $r
      fi
      i=$((i + 1))
    done
  done
  IFS=$OLD_IFS

}
export -f a.os.dmi_info2
