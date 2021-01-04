#!/bin/bash

# argument is optional: host id to exclude

BASEDIR="$HOME/.clipsync"
MYDIR="$(realpath "$(dirname "$0")")"
localid="`cat ~/.clipsync/hostid`"
excludeid="$1"
MAXSIZE=10000000

listallsocks() {
	find "$BASEDIR/sock_in" "$BASEDIR/sock_out" -type s
}

listallhosts() {
	listallsocks | while read -r line; do
		bn="`basename "$line"`"
		echo "$bn" | cut -d '+' -f 1
	done | sort | uniq
}

sendtohost() {
	host="$1"
	if [ "$host" = "$localid" ]; then return; fi
	if [ ! -z "$excludeid" ] && [ "$host" = "$excludeid" ]; then return; fi
	file="$2"
	for sock in `listallsocks | grep -F "/${host}+" | sort`; do
		"$MYDIR/clipsyncdpush.sh" "$sock" < "$file" &>/dev/null
		if [ $? -eq 0 ]; then
			break
		else
			# clean up old sockets we cant connect to
			rm -f "$sock"
		fi
	done
}

TEMPFILE="`tempfile 2>/dev/null`"
if [ $? -ne 0 ]; then
	TEMPFILE="/tmp/_clip_tempcsdp_yssh$USER"
fi

cat > "$TEMPFILE"
if [ -z "`cat "$TEMPFILE"`" ]; then exit 0; fi
if [ `cat "$TEMPFILE" | wc -c` -gt $MAXSIZE ]; then exit 0; fi

for h in `listallhosts`; do
	sendtohost "$h" "$TEMPFILE"
done
