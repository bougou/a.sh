#!/bin/bash

function dedup_lines_by_col() {
  cat <<EOF
Usage: $0 <file> [<column_index>] [<separator>]"

    file:           input file
    column_index:   default to 0, index starts at 1
                    If column_index is 0, this script will remove the EXACT
                    same lines and keep only one line of them left.
                    If column_index is not 0, this script will remove the lines
                    that the SPECIFIED COLUMN has the same strings, and keep
                    only one line (which line is undetermined) of them left.
    seperator:      default to space character, used to separate a line into columns.

    This script will print the result to stdout.
EOF

  if [ $# -lt 1 ]; then
    usage && exit 1
  fi

  file=$1

  [[ -n $2 ]] && index=$2 || index=0
  [[ -n $3 ]] && sep=$3 || sep=" "

  if [[ $index -eq 0 ]]; then
    cat $file | sort | uniq
    exit
  fi

  cat "$file" | sort -t "$sep" -k "$index" | awk -F "$sep" -v KEY="$index" '{if ($KEY==TEMP) {} else {TEMP=$KEY; print $0} }'

}

export -f a.file.dedup_lines_by_col
