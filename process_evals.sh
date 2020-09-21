#!/bin/bash
#
# This simple script daemonizes inotify which waits for a close_write event 
# in the eval directories for all app servers recursevely
# Then it gunzip the file and curl fetch it via squid cache
# This is not a moved_to event since the source is on different partition
#
. /root/.cc_profile

# evals-c95fe066ae1616aa45a10b2891b90806d546e8d2048f0f5e07b2625e8fb95150.json.gz CLOSE_WRITE,CLOSE /home/appch2com/public_html/0/eval/

# This is non-blocking script as we monitor eval dirs for all app servers
nohup inotifywait -q -r -m -e close_write --format '%e %f %w' $WEBHOME/0/eval | \
(
while read event file dir
do 
  logger -t process_evals "$file $event $dir"

  # Parse the app server index
#  APPIDX=$(echo $dir | cut -f 5 -d'/')

  # get file extension
  extension="${file##*.}"

  # DO NOT gunzip json
  if [[ "$extension" != "json" ]]; then

    # Gunzip the file
    gunzip -f $dir/$file

  else

    # Change permissions
    chmod 666 $dir/$file

    # Curl JSON
    curl -s --compressed -H 'Cache-Control: no-cache' "http://cache.chesscheat.com:3128/$file" > /dev/null

    # Remove file if it is still there
#    if [[ -f $dir/$file ]]; then
#      unlink $dir/$file
#    fi

  fi

done
) &
