function a.config.update_config() {
  key=$1
  value=$2
  file=$3
  sep=$4

  # Omit $value here, in case there is sensitive information
  echo "[Configuring] '$key' in '$file'"

  if [[ $sep == ":" ]]; then
    if grep -E -q "^$key$sep" "$file"; then
      sed -r -i "s@^$key$sep.*@$key$sep $value@g" "$file" #note that no config values may contain an '@' char
    else
      echo "$key$sep $value" >>"$file"
    fi
  elif [[ $sep == "=" ]]; then
    crudini --set "$file" '' "$key" "$value"
  else
    echo "Unknown separator, ignore"
  fi
}
export -f a.config.update_config

# Todo, merge into above update_config function
function a.config.mod_file() {
  local _file=$1
  local _option=$2
  local _value=$3

  if $(cat $_file | grep -sq "^$_option ="); then
    sed -i "s|\($_option =\).*|\1 $_value|g" $_file
  else
    echo "$_option = $_value" >>$_file
  fi
}
export -f a.config.mod_file
