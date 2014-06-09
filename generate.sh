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

echo -n > "$tmp"/to_copy
echo -n > "$tmp"/to_convert
cat "$tmp"/mp3_missing | while read file ; do
	if [ -f "$SOURCE"/"$file" ]; then
		echo "$file" >> "$tmp"/to_copy
	else
		echo "$file" >> "$tmp"/to_convert
	fi
done

i=0
N=`wc -l < "$tmp"/to_copy`
cat "$tmp"/to_copy | while read file ; do
	i=$(($i+1))
	echo -en '\r'Copying new mp3 and ogg files..." $i/$N           "
	cp "$SOURCE"/"$file" "$DEST"/"$file"
done
echo -e '\r'Copying new mp3 and ogg files... done"           "

i=0
N=`wc -l < "$tmp"/to_convert`

rm "$tmp"/to_convert.* -fr
split -l $((($N+$threads-1)/$threads)) "$tmp"/to_convert "$tmp"/to_convert.

# run workers
rm -fr "$tmp"/stop
for list in "$tmp"/to_convert.*; do
	bash "$SCDIR"/worker.sh "$list" "$SOURCE" "$DEST" &
done

trap ctrl_c INT

sleep 1

function ctrl_c() {
        echo killing workers...
	touch "$tmp"/stop
	echo waiting for workers to stop...
	while [ ! -z "`find "$tmp"/ -name '*.p'`" ]; do
		sleep 0.5
	done
	exit
}

echo "Converting flac files..."
while [ ! -z "`find $tmp/ -name '*.p'`" ]; do
	echo -en '\r'
	cat "$tmp"/*.p
	echo -n '('`cat "$tmp"/*.p | sed -e 's/\/[0-9]\+/+/g' | sed -e 's/$/0\n/' | bc -l`/$N total')'
	sleep 0.5
done


rm -fr "$tmp"
echo
echo Done\!
