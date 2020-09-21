#!/bin/bash
#
# This simple script daemonizes inotify which waits for a moved_to event
# in the queue directories for all app servers recursevely
# Then it parses the app server index from the target directory name
# and runs an extractor script in background
#
. /root/.cc_profile

# MOVED_TO Akobian.pgn.gz /mnt/PGNs/queued/0/

# This is non-blocking script as we monitor queue dir for all app servers
nohup inotifywait -q -r -m -e moved_to --format '%e %f %w' $QUEUEDIR | \
(
while read event file dir
do 
  # Parse the app server index
  APPIDX=$(echo $dir | cut -f 5 -d'/')

  # Log the event into system log
  logger -t extract_queued "$file $event $dir"

  # Fire an extractor script in background
  $APPDIR/extractor.sh $APPIDX &
done
) &
