#!/bin/bash

SCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tmp="$SCDIR"/tmp

SOURCE=$1
DEST=$2

threads=6
mkdir -p "$DEST"
mkdir -p "$tmp"

echo Generating difference files...
(cd "$SOURCE" && \
	find . -iname '*.mp3' -or -iname '*.ogg' && \
	find . -iname '*.flac' | sed -e 's/\.flac$/.ogg/' \
) | sort > "$tmp"/mp3_source
(cd "$DEST" && \
	find . -iname '*.mp3' -or -iname '*.ogg' \
) | sort > "$tmp"/mp3_dest

comm -3 -2 "$tmp"/mp3_source "$tmp"/mp3_dest > "$tmp"/mp3_missing
comm -3 -1 "$tmp"/mp3_source "$tmp"/mp3_dest > "$tmp"/mp3_todelete

echo Removing old files...
tr '\n' '\0' < "$tmp"/mp3_todelete | \
	(cd "$DEST" && xargs -0 rm -fr)
find "$DEST" -not -path "$DEST" -and -type d -and -empty -exec rm -fr {} +

echo Updating directory structure...
(cd "$SOURCE" && \
	find . -type d -print0 \
) | (cd "$DEST" && \
	xargs -0 mkdir -p \
)

$SCDIR/bpc/server "$tmp"/to_convert $threads $SCDIR/flac2ogg.sh > /dev/null 2>&1 &
server_pid=$!

echo -n > "$tmp"/to_copy
cat "$tmp"/mp3_missing | while read file ; do
	if [ -f "$SOURCE"/"$file" ]; then
		echo "$file" >> "$tmp"/to_copy
	else
		$SCDIR/bpc/enqueue "$tmp"/to_convert "$SOURCE/${file%.ogg}.flac" "$DEST/$file"
	fi
done
Nc=`wc -l < "$tmp"/to_convert`

i=0
N=`wc -l < "$tmp"/to_copy`
cat "$tmp"/to_copy | while read file ; do
	i=$(($i+1))
	echo -en '\r'Copying new mp3 and ogg files..." $i/$N           "
	cp "$SOURCE"/"$file" "$DEST"/"$file"
done
echo -e '\r'Copying new mp3 and ogg files... done"           "

trap ctrl_c INT

sleep 1

function ctrl_c() {
	echo
        echo killing worker server...
	rm "$tmp"/to_convert
	echo -n waiting for worker server to finish
	while [ -n "$(ps -hp $server_pid)" ]; do
		sleep 1 && echo -n .
	done
	echo
	echo finished
	rm -fr "$tmp"
	exit
}

echo "Converting flac files..."
while [ -s "$tmp"/to_convert ]; do
	echo -en '\r'
	N=`wc -l < "$tmp"/to_convert`
	echo -n $(($Nc-$N))/$Nc done
	sleep 0.5
done
echo -e '\r'finished

ctrl_c
