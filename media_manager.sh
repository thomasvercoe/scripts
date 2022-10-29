#!/bin/bash

#x="A.Grin.Without.a.Cat.1of2.Fragile.Hands.x264.AC3.MVGroup.org.mkv"
#y='/data/thomas/torrents/completed/shows'

x="$2"
y="$3"


ARG_DIR="$y"
ARG_PATH="$y/$x"
ARG_NAME="$x"
ARG_LABEL="N/A"

log='/tmp/media_manager.sh.log'

echo "called media_manager.sh for $x at $(date +"%T")" >> $log


permission_fix () {
    echo "fixing permissions at $(date +"%T")" >> $log
    chmod -R 777 /data/thomas
}


jellyfin_rescan () {
    permission_fix
    echo "running jellyfin rescan at $(date +"%T")" >> $log
    curl -v -d "" -H "X-MediaBrowser-Token: 50b2821357244e229265c7f967dcd174" http://127.0.0.1:8096/library/refresh  >> $log
}

exiting () {
    permission_fix
    echo "backing up torrent_files to torrent_files_archive at $(date +"%T")" >> $log
    echo "copying torrent_files to torrent_files_archive_tmp at $(date +"%T")" >> $log
    cp -r "/data/thomas/torrents/torrent_files" "/home/thomas/Downloads/torrent_files_archive_tmp"
    echo "fixing permisions for torrent_files_archive_tmp at $(date +"%T")" >> $log
    chmod -R 777 /home/thomas/Downloads/torrent_files_archive_tmp
    echo "moving torrent_files_archive_tmp to torrent_files_archive at $(date +"%T")" >> $log
    rm -r "/home/thomas/Downloads/torrent_files_archive"
    mv "/home/thomas/Downloads/torrent_files_archive_tmp" "/home/thomas/Downloads/torrent_files_archive"
    echo "fixing permisions for torrent_files_archive at $(date +"%T")" >> $log
    chmod -R 777 /home/thomas/Downloads/torrent_files_archive
    echo "cleaning torrent_files_archive_tmp at $(date +"%T")" >> $log
    #rm -r "/home/thomas/Downloads/torrent_files_archive_tmp"
    jellyfin_rescan
    echo "exiting at $(date +"%T")" >> $log
    exit
}

anidb_cli () {
    echo "passing to anidbcli at $(date +"%T")" >> $log
    permission_fix
    python3.9 -m anidbcli  -r -e mkv,mp4 api -u "api_username" -p "Anidb2141" -sr "/data/thomas/media/Anime/%a_english%/%ep_no% - %ep_english%" "/data/thomas/torrents/completed/anime_tmp"  >> $log
}




permission_fix

#shows
if [[ $ARG_DIR == '/data/thomas/torrents/completed/shows' ]]
then
    echo "asigning to shows at $(date +"%T")" >> $log
    ARG_LABEL="TV"

filebot -script fn:amc --output "/data/thomas/media" --action hardlink --conflict skip -non-strict --log-file /tmp/amc.log --def unsorted=n music=n artwork=n excludeList=amc.txt ut_dir="$ARG_PATH" ut_kind="multi" ut_title="$ARG_NAME" ut_label="$ARG_LABEL" >> $log


#films
elif [[ $ARG_DIR == '/data/thomas/torrents/completed/films' ]]
then
    echo "asigning to films at $(date +"%T")" >> $log
    ARG_LABEL="Movies"

filebot -script fn:amc --output "/data/thomas/media" --action hardlink --conflict skip -non-strict --log-file /tmp/amc.log --def unsorted=n music=n artwork=n excludeList=amc.txt ut_dir="$ARG_PATH" ut_kind="multi" ut_title="$ARG_NAME" ut_label="$ARG_LABEL" >> $log


#music
elif [[ $ARG_DIR == '/data/thomas/torrents/completed/music' ]]
then
    echo "asigning to music at $(date +"%T")" >> $log
    ARG_LABEL="Music"

filebot -script fn:amc --output "/data/thomas/media" --action hardlink --conflict skip -non-strict --log-file /tmp/amc.log --def unsorted=n music=y artwork=n excludeList=amc.txt ut_dir="$ARG_PATH" ut_kind="multi" ut_title="$ARG_NAME" ut_label="$ARG_LABEL" >> $log



#anime
elif [[ $ARG_DIR == "/data/thomas/torrents/completed/anime" ]]
then
    echo "asigning to anime at $(date +"%T")" >> $log
    hardlink="/data/thomas/torrents/completed/anime_tmp/$ARG_NAME"
    permission_fix
    
    if [ -d "/data/thomas/torrents/completed/anime/$ARG_NAME" ] 
    then
        echo "the torrent contains a directory, attempting to hardlink files from within the first directory at $(date +"%T")" >> $log
        mkdir "/data/thomas/torrents/completed/anime_tmp/$ARG_NAME"
        permission_fix
        shopt -s nullglob
        for file in "/data/thomas/torrents/completed/anime/$ARG_NAME/"*
        do
            echo "$file at $(date +"%T")" >> $log
            file_base="$(basename "$file")"
            echo "hardlinking files to anime_tmp at $(date +"%T")" >> $log
            ln "$file" "$hardlink/$file_base"
        done
        shopt -u nullglob

        anidb_cli

    else
        echo "the torrent does not contain a directory, attempting to hardlink file at $(date +"%T")" >> $log
        ln "$ARG_PATH" "$hardlink"
        anidb_cli
    fi

    permission_fix

    find "/data/thomas/torrents/completed/anime_tmp" -not -path "/data/thomas/torrents/completed/anime_tmp" -type d -empty -delete


#books
elif [[ $ARG_DIR == '/data/thomas/torrents/completed/books' ]]
then
    echo "asigning to books at $(date +"%T")" >> $log
    hardlink="/data/thomas/torrents/completed/books_tmp/$ARG_NAME"

    echo "processing at $(date +"%T")" >> $log

    cp -r "$ARG_PATH" "$hardlink"

    echo "adding to calibre database at $(date +"%T")" >> $log
    calibredb add -r "$hardlink"  >> $log

    echo "cleaning books_tmp at $(date +"%T")" >> $log
    rm -r "$hardlink"

    jellyfin_rescan

    exiting

#audiobooks
elif [[ $ARG_DIR == '/data/thomas/torrents/completed/audiobooks' ]]
then
    echo "asigning to audiobooks at $(date +"%T")" >> $log
    hardlink="/data/thomas/media/Audiobooks/$ARG_NAME"

    echo "processing at $(date +"%T")" >> $log

    ln "$ARG_PATH" "$hardlink"

    exiting

else
    echo "not assigned at $(date +"%T")" >> $log
    exiting
fi

exiting