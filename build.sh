#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

output_file="${SCRIPT_DIR}/a.sh"
>$output_file
echo "#!/bin/bash" >>$output_file
while read file; do

  echo
  echo "handle file: $file"

  echo >>$output_file
  cat $file | grep -v '^#' >>$output_file

done <<<"$(find ${SCRIPT_DIR}/src | grep .sh\$)"
