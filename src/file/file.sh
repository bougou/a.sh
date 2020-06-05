
# If a line ends with a \, strip the backslash and print the line with no terminating newline;
# otherwise print the line with a terminating newline.
function a.file.combine_lines_backslash() {
  if [[ $# -ge 1 ]]; then
    # read from file, only use the first param, others are ignored
    local CONTENT="$(cat $1)"
  else
    # echo "Read content from stdin..."
    # echo "You can send your content through pipe, like: echo "something" | this_script"
    local CONTENT=$(</dev/stdin)
  fi

  echo "$CONTENT" | awk '{if (sub(/\\$/,"")) printf "%s", $0; else print $0}'
}
export -f a.file.combine_lines_backslash
