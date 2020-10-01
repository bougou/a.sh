function a.db.create_mysql_db_user_pass() {
  if [[ $# -lt 1 ]]; then
    echo "Error: Invalid parameters"
    cat <<EOF
Usage: $0 <db_user_pass_str> [<db_host> <db_port> <db_authuser> <db_authpass>]
The format of <db_user_pass_str> is: "<db1name>/<db1user>/<db1pass>[/<db1charset>/<db1collate>];<db2name>/<db2user>/<db2pass>[/<db2charset>/<db2collate>]"
When <db_user_pass_str> contains multiple parts separated by semicolon, it MUST be quoted.
If any of the <db_host>, <db_port>, <db_authuser>, <db_authpass> is omitted, its value will be retrieved from environment variables:
MYSQL_DB_HOST, MYSQL_DB_PORT, MYSQL_DB_AUTHUSER, MYSQL_DB_AUTHPASS.
EOF
    return 1
  fi

  if ! command -v mysql >/dev/null; then
    echo "Error: not found mysql command"
    return 1
  fi

  local db_user_pass_str="$1"
  local db_user_pass_array=(${db_user_pass_str//;/ })

  local db_host="${MYSQL_DB_HOST:-127.0.0.1}"
  local db_port="${MYSQL_DB_PORT:-3306}"
  local db_authuser="${MYSQL_DB_AUTHUSER:-root}"
  local db_authpass="${MYSQL_DB_AUTHPASS:-''}"

  [[ $# -ge 2 ]] && db_host="$2"
  [[ $# -ge 3 ]] && db_port="$3"
  [[ $# -ge 4 ]] && db_authuser="$4"
  [[ $# -ge 5 ]] && db_authpass="$5"

  local mysql_cmd="mysql -Ns -h${db_host} -P${db_port} -u${db_authuser} -p${db_authpass}"

  for i in ${db_user_pass_array[@]}; do
    db_user_pass=(${i//\// })
    if [[ ${#db_user_pass[@]} -lt 3 ]]; then
      echo "db_user_pass has wrong format ('dbname/dbuser/dbpass[/dbcharset/dbcollate][;dbname/dbuser/dbpass[/dbcharset/dbcollate]]')! Exit" && return 1
    fi
    _dbname=${db_user_pass[0]}
    _dbuser=${db_user_pass[1]}
    _dbpass=${db_user_pass[2]}

    # default value
    _dbcharset="utf8mb4"
    _dbcollate="utf8mb4_bin"

    if [[ ${#db_user_pass[@]} -ge 4 ]]; then
      _dbcharset=${db_user_pass[3]}
    fi

    if [[ ${#db_user_pass[@]} -ge 5 ]]; then
      _dbcollate=${db_user_pass[4]}
    fi

    echo "Create the following database/user/pass"
    echo "dbname: $_dbname"
    echo "dbuser: $_dbuser"
    echo "dbpass: $_dbpass"
    echo "dbcharset: $_dbcharset"
    echo "dbcollate: $_dbcollate"
    echo

    {
      cat <<EOSQL
CREATE DATABASE IF NOT EXISTS \`${_dbname}\` CHARACTER SET \`${_dbcharset}\` COLLATE \`${_dbcollate}\`;
GRANT ALL PRIVILEGES ON \`${_dbname}\`.* TO \`${_dbuser}\`@\`127.0.0.1\` IDENTIFIED WITH mysql_native_password BY "${_dbpass}";
GRANT ALL PRIVILEGES ON \`${_dbname}\`.* TO \`${_dbuser}\`@\`localhost\` IDENTIFIED WITH mysql_native_password BY "${_dbpass}";
GRANT ALL PRIVILEGES ON \`${_dbname}\`.* TO \`${_dbuser}\`@\`%\` IDENTIFIED WITH mysql_native_password BY "${_dbpass}";
FLUSH PRIVILEGES;
EOSQL

    } | $mysql_cmd

  done
}
export -f a.db.create_mysql_db_user_pass

function a.db.get_mysql_db_all_size() {
  mysql "$@" -e "
use information_schema;
select concat(sum(data_length) / 1024 / 1024 / 1024, ' G') from tables where table_schema not in ('information_schema', 'performance_schema', 'test');
"

  # output example
  cat >/dev/null <<EOF
+-----------------------------------------------------+
| concat(sum(data_length) / 1024 / 1024 / 1024, ' G') |
+-----------------------------------------------------+
| 0.002191769890 G                                    |
+-----------------------------------------------------+
EOF
}
export -f a.db.get_mysql_db_all_size
