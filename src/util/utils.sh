function a.util.is_number() {
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}
export -f a.util.is_number

function a.util.compare_version() {
  # the leading and trailing space/dot will be ignored. 1, .1, 1. are equal versions.
  # Given two versions, convert them into two arrays by splitting the version string by dot(.).
  # Recursively comparing elements of the same index from the two arrays until found inequality or loop end.
  # If the two elments are both pure numbers, compare them numerically, or else compare them lexicographically/alphanumerically
  # 8 and 008 are considered to be numerically equal.
  # 1.1 and 1.001 are considered to be equal versions.

  local _version1="${1:-0}"
  local _version2="${2:-0}"
  local _op="${3:-eq}"

  # operator(OP) is one of eq, ne, lt, le, gt, or ge,
  # if op is NOT a valid string, forcely set to 'eq'
  if ! [[ $_op == 'eq' || $_op == 'ne' || $_op == 'lt' || $_op == 'le' || $_op == 'gt' || $_op == 'ge' ]]; then
    $_op == 'eq'
  fi

  TRUE=0
  FALSE=1

  # the leading and trailing space/dot will be ignored by converting to array
  version1_array=(${_version1//./ })
  version2_array=(${_version2//./ })
  version2_array_len=${#version2_array[@]}

  for i in "${!version1_array[@]}"; do
    v1=${version1_array[i]}

    if [ $i -gt $((version2_array_len - 1)) ]; then
      [[ $_op == 'gt' || $_op == 'ge' || $_op == 'ne' ]] && return $TRUE || return $FALSE
    else
      v2=${version2_array[i]}

      if $(a.util.is_number "${v1}") && $(a.util.is_number "${v2}"); then
        if [ "$v1" -gt "$v2" ]; then # numeric greater
          [[ $_op == 'gt' || $_op == 'ge' || $_op == 'ne' ]] && return $TRUE || return $FALSE
        elif [[ "$v1" -lt "$v2" ]]; then # numeric lower
          [[ $_op == 'lt' || $_op == 'le' || $_op == 'ne' ]] && return $TRUE || return $FALSE
        else
          continue # numeric equal
        fi
      else
        if [[ "$v1" > "$v2" ]]; then # lexicographically greater
          [[ $_op == 'gt' || $_op == 'ge' || $_op == 'ne' ]] && return $TRUE || return $FALSE
        elif [[ "$v1" < "$v2" ]]; then # lexicographically lower
          [[ $_op == 'lt' || $_op == 'le' || $_op == 'ne' ]] && return $TRUE || return $FALSE
        else
          continue # lexicographically equal
        fi
      fi
    fi
  done

  # If the above for loop does not return, it means all subparts of the two versions are 'numeric equal' or 'lexicographically equal'.
  if [[ $_op == 'eq' || $_op == 'ge' || $_op == 'le' ]]; then
    return $TRUE
  fi

  return $FALSE

}
export -f a.util.compare_version

function a.util.download_file() {
  local _filepath=$1
  local _fileurl=$2

  if [[ -e "$_filepath" ]]; then
    zflag="-z $_filepath"
  else
    zflag=
  fi

  echo "Downloading file: $(basename $_filepath)"
  curl ${zflag} -o "$_filepath" "$_fileurl"
}
export -f a.util.download_file

function a.util.check_variables() {
  # helper function to make sure variables NOT EMPTY
  # usage: check_variables var1 var2 var3 ...
  for i in "$@"; do
    eval _value=\$${i}
    if [[ $_value == '' ]]; then
      echo "[X] $i must be set and not empty"
      exit 1
    else
      echo "[Y] $i: $_value"
    fi
  done
}
export -f a.util.check_variables
