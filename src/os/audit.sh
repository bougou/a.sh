function a.os.audit_human_time() {
  if [[ $# -ge 1 ]]; then
    # read from file, only use the first param, others are ignored
    local CONTENT="$(cat $1)"
  else
    # echo "Read content from stdin..."
    # echo "You can send your content through pipe, like: echo "something" | this_script"
    local CONTENT=$(</dev/stdin)
  fi

  echo "$CONTENT" | perl -ne 'use POSIX qw(strftime); chomp; if ( /(.*msg=audit\()(\d+)(\.\d+:\d+.*)/ ) { $td = scalar strftime "%F %H:%M:%S", localtime $2; print "$1$td$3\n"; }'

  # example
  cat >/dev/null <<EOF
# raw lines in /var/log/audit/audit.log
type=USER_AUTH msg=audit(1601641999.669:17863321): pid=21420 uid=0 auid=4294967295 ses=4294967295 msg='op=password acct="(unknown)" exe="/usr/sbin/sshd" hostname=? addr=106.12.122.92 terminal=ssh res=failed'

# after
type=USER_AUTH msg=audit(2020-10-02 20:33:19.669:17863321): pid=21420 uid=0 auid=4294967295 ses=4294967295 msg='op=password acct="(unknown)" exe="/usr/sbin/sshd" hostname=? addr=106.12.122.92 terminal=ssh res=failed'
EOF

}
export -f a.os.audit_human_time

# strftime "%a %b %e %H:%M:%S %Y"
#          Fri Oct  2 20:33:19 2020
