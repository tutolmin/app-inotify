#!/bin/bash
#
# This simple script daemonizes inotify which waits for a close_write event
# in the incoming directories for all app servers
# Then it parses the app server index from the target directory name
# and parses the extractor mode from the file name.
# Evaluation files in JSON formate go to the web home dir
# PGNs go to the corresponding queue directory for cache upload
#
. /root/.cc_profile

# CLOSE_WRITE:CLOSE games-6-mo2019tutolmin-5e5a2207ecfa3.txt.gz /mnt/PGNs/incoming/0/
# CLOSE_WRITE:CLOSE evals-3245234256256245624565a2207ecfa3.json.gz /mnt/PGNs/incoming/0/

# Operation is non-blocking since we want all events served
nohup inotifywait -q -r -m -e close_write --format '%e %f %w' $INCOMINGDIR | \
(
while read event file dir
do 
  # Parse the app server index
  APPIDX=$(echo $dir | cut -f 5 -d'/')

  # A mandatory parameter should be a positive integer <APPMAX
  if [[ ! "$APPIDX" =~ ^[0-9]+$ || "$APPIDX" -ge $APPMAX ]]; then
    logger -t move_cache_incoming "Invalid app server index: '$APPIDX' for $file in $dir"
    exit
  fi

  # Fetch the extractor mode (games|evals) from filename
  MODE=$(echo $file | cut -f 1 -d'-')

  # JSON file with game evaluation data
  if [[ "$MODE" == "evals" ]]; then

    # Log the event into system log
    logger -t move_cache_incoming "Moving $dir$file -> $WEBHOME/$APPIDX/eval"

    # Move gzipped file to web dir
    mv $dir/$file $WEBHOME/$APPIDX/eval

  else # regular PGN cache upload

    # Log the event into system log
    logger -t move_cache_incoming "Moving $dir$file -> $QUEUEDIR/$APPIDX"
 
    # Move the file into respective queue directory
    mv $dir/$file $QUEUEDIR/$APPIDX

  fi # end of mode switch
done
) &
