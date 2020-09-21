#!/bin/bash
#
# This simple script daemonizes inotify which waits for a close_write event
# in a web_home_hash_file directory and runs an curl script in background
# The files in the directory appear during extractor processing new game archive
#

. /root/.cc_profile

# CLOSE_WRITE:CLOSE fff82e49211f35393ec042e705a0c81d.json /home/appch2com/public_html/0/hash/

: '
#
# This is a non-blocking approach. It only executes a single inotifywait on recursive directories
# As a result all the events are processed. Which result in unnecessary I/O on lock file check
#
nohup inotifywait -q -m -e close_write --format '%e %f %w' $WEBHOME/?/hash/ | \
(
while read event file dir
do 
  # Parse the app server index
  APPIDX=$(echo $dir | cut -f 5 -d'/')

  # Log the event into system log
#  logger -t inotify "$event $APPIDX $dir"

  # Check if there is a lock file already
  if [[ ! -e "$CLOCK$APPIDX" ]]; then

    # Fire an extractor script in background
    $APPDIR/curl.sh $APPIDX &
  fi
done
) &
'

#
# Blocking approach. Executes APPMAX number of inotifywait for each web_home hash directory.
# inotifywait exits as soon as event is received. Skips all consequetive events 
# until processing of the current one has not been finished.
#
for APPIDX in $(eval echo "{0..`expr $APPMAX - 1`}")
do
  while inotifywait -qq -e close_write $WEBHOME/$APPIDX/hash/
  do
    # Log the event into system log
    logger -t curl_extracted "CLOSE_WRITE:CLOSE in $WEBHOME/$APPIDX/hash/"

    # Fire an extractor script
    $APPDIR/curl.sh $APPIDX
  done &
done

