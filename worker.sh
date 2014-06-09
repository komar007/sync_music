#!/bin/bash

SCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tmp="$SCDIR"/tmp

SOURCE=$2
DEST=$3

N=`wc -l < "$1"`
echo -n > "$1".p
cat "$1" | while read file ; do
	if [ -f "$tmp"/stop ]; then
		break
	fi
	i=$(($i+1))
	echo -n $i/$N" " > "$1".p
	bash "$SCDIR"/flac2ogg.sh "$SOURCE"/"${file%.ogg}.flac" "$DEST"/"$file" > /dev/null 2>&1
done
rm "$1".p
