#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ROOT_DIR="$(cd ${SCRIPT_DIR}/.. && pwd)"
SRC_DIR="$(cd ${ROOT_DIR}/src && pwd)"

output_file="${ROOT_DIR}/a.sh"
>$output_file
echo "#!/bin/bash" >>$output_file
while read file; do

  echo
  echo "handle file: $file"

  echo >>$output_file
  cat $file | grep -v '^#' >>$output_file

done <<<"$(find ${SRC_DIR} | grep .sh\$)"
