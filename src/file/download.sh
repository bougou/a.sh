#!/bin/bash

# download_newer_file will download from the specified url (arg2) only if
# the remote docuement is newer than the specified file path (arg1).
function download_newer_file() {
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
