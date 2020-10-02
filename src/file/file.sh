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

function a.file.show_filesystem_stat() {
  input_file=$1

  stat_format=""
  while read opt comment; do
    stat_format="$stat_format\n(%$opt) $comment # : $opt"
  done <<EOF
  %a     Free blocks available to non-superuser
  %b     Total data blocks in file system
  %c     Total file nodes in file system
  %d     Free file nodes in file system
  %f     Free blocks in file system
  %C     SELinux security context string
  %i     File System ID in hex
  %l     Maximum length of filenames
  %n     File name
  %s     Block size (for faster transfers)
  %S     Fundamental block size (for block counts)
  %t     Type in hex
  %T     Type in human readable form
EOF

  stat -f --printf="$stat_format" $input_file | awk -F'#' '{printf "%-60s%-20s\n", $1, $2}'
}
export -f a.file.show_filesystem_stat

function a.file.show_file_stat() {
  input_file=$1

  stat_format=""
  while read opt comment; do
    stat_format="$stat_format\n(%$opt) $comment # : $opt"
  done <<EOF
  %a     Access rights in octal
  %A     Access rights in human readable form
  %b     Number of blocks allocated (see %%B)
  %B     The size in bytes of each block reported by %%b
  %C     SELinux security context string
  %d     Device number in decimal
  %D     Device number in hex
  %f     Raw mode in hex
  %F     File type
  %g     Group ID of owner
  %G     Group name of owner
  %h     Number of hard links
  %i     Inode number
  %n     File name
  %N     Quoted file name with dereference if symbolic link
  %o     I/O block size
  %s     Total size, in bytes
  %t     Major device type in hex
  %T     Minor device type in hex
  %u     User ID of owner
  %U     User name of owner
  %x     Time of last access
  %X     Time of last access as seconds since Epoch
  %y     Time of last modification
  %Y     Time of last modification as seconds since Epoch
  %z     Time of last change
  %Z     Time of last change as seconds since Epoch
EOF

  # the '#' in the echo will be used as a spearator
  stat --printf="$stat_format" $input_file | awk -F'#' '{printf "%-60s%-20s\n", $1, $2}'

}
export -f a.file.show_file_stat
