a=$1
OUTF=$2

ARTIST=`metaflac "$a" --show-tag=ARTIST | sed s/.*=//g`
TITLE=`metaflac "$a" --show-tag=TITLE | sed s/.*=//g`
ALBUM=`metaflac "$a" --show-tag=ALBUM | sed s/.*=//g`
GENRE=`metaflac "$a" --show-tag=GENRE | sed s/.*=//g`
TRACKNUMBER=`metaflac "$a" --show-tag=TRACKNUMBER | sed s/.*=//g`
DATE=`metaflac "$a" --show-tag=DATE | sed s/.*=//g`

oggenc -q8 --discard-comments -a "$ARTIST" -t "$TITLE" -l "$ALBUM" -G "$GENRE" -N "$TRACKNUMBER" -d "$DATE" -o "$OUTF" "$a" > /dev/null 2>&1
