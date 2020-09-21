#!/bin/bash
#
# This simple script daemonizes inotify which waits for a delete event
# in web_home_hash_file directory
# Then it runs an extractor script

. /root/.cc_profile

# DELETE fff82e49211f35393ec042e705a0c81d.json /home/appch2com/public_html/0/hash/

#
# Blocking approach. Executes APPMAX number of inotifywait for each web_home hash directory.
# inotifywait exits as soon as event is received. Skips all consequetive events 
# until processing of the current one has not been finished.
#
for APPIDX in $(eval echo "{0..`expr $APPMAX - 1`}")
do
  while inotifywait -qq -e delete $WEBHOME/$APPIDX/hash/
  do
    # Log the event into system log
    logger -t extract_deleted "DELETE in $WEBHOME/$APPIDX/hash/"

    # Wait some time in order to skip some deletions
    sleep $SLEEPDELETIONS

    # Fire an extractor script
    $APPDIR/extractor.sh $APPIDX

  done &
done

