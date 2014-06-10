sync_music
==========

Incrementally synchronize music with your player with automatic flac -> ogg conversion

This script copies all mp3 and ogg files from source to destination directory, replicating the directory structure.
Additionally, all flac files are converted and to ogg to reduce space and placed in destination directory.
Only files which do not exist in destination directory are copied, and files in destination directory which do not exist in the source directory are removed.
Tracking changes in files is not supported.

## Usage

    ./sync source_dir dest_dir
