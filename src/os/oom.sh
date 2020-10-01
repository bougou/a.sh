function a.os.show_top_oom_scores() {
  printf "%5s %6s %s\n" "SCORE" "PID" "NAME"

  for proc in $(find /proc -maxdepth 1 -regex '/proc/[0-9]+'); do
    printf "%5d %6d %s\n" \
      "$(cat $proc/oom_score)" \
      "$(basename $proc)" \
      "$(cat $proc/cmdline | tr '\0' ' ' | head -c 50)"
  done 2>/dev/null | sort -nr | head -n 10
}

export -f a.os.show_top_oom_scores
