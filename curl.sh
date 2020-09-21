#!/bin/bash
#
# This script is called whenever a file is written in the app server 'web_dir/hash'
# It builds the list of URLs to fetch from app server via SQUID proxy
# Then executes a curl process to fetch the file in a temp directory
# Afterwards the fetched files are matched to the source files in the web dir
# Optionally the contents of the files are compared to catch the collisions
# If a temp file is found in web dir it is deleted
#
. /root/.cc_profile

# App server index
APPIDX=$1

# A mandatory parameter should be a positive integer <APPMAX
if [[ "$#" -ne 1 || ! "$APPIDX" =~ ^[0-9]+$ || "$APPIDX" -ge $APPMAX ]]; then
  logger -t curl "$0 Invalid parameter: '$APPIDX'"
  exit
fi

WORKDIR=$WEBHOME/$APPIDX/hash
LOCKFILE="$CLOCK$APPIDX"
URLLIST="$APPDIR/urllist${APPIDX}.txt"

# Create lockfile if not exist
if [[ ! -e $LOCKFILE ]]; then
#  logger -t curl "Creating $LOCKFILE < $$"
#  logger -t curl "Creating $LOCKFILE"
  echo $$ > $LOCKFILE
else
  logger -t curl "$LOCKFILE present!"
  exit
fi

# Forever loop
while : ; do

  # Change directory
  cd $WORKDIR

  logger -t curl "Building a urllist"

  # Empty urllist
  echo "" > $URLLIST

  # Find files to fetch
#  find . -maxdepth 1 -regextype posix-egrep -regex "\./[0-9a-f]{32}\.json" \
  find . -maxdepth 1 -type f \
    -fprintf $URLLIST "url=http://cache.chesscheat.com:3128/%f\n-O\n"

  URLS=`expr \`wc -l $URLLIST|awk '{print $1}'\` / 2`
  logger -t curl "Fetching $URLS URLs from the web"

  # Some files found, proceed
  if [[ -s $URLLIST ]]; then

    # Make a temp directory
    TMPDIR=`mktemp -d`
    cd $TMPDIR

    # Fetch the files via network
#    curl -s -K $URLLIST
    curl -s --compressed -K $URLLIST

#    logger -t curl "Finding files to compare"

    logger -t curl "Comparing files and deleting matches"

    # Iterate through each fetched file
    for FILE in `find $TMPDIR -type f -printf "%f\n"`; do

      # Check if file still exists in webdir
      if [[ -f $WORKDIR/$FILE ]]; then

        # Compare fetched files
        if [[ "$HASHCOLLISIONS" = "catch" ]]; then 

          cmp -s $TMPDIR/$FILE $WORKDIR/$FILE
      
          logger -t curl "Comparing $FILE in $WORKDIR and $TMPDIR"

          # If files do NOT match, save the collision
          if [[ $? != 0 ]]; then

            logger -t curl "Hash collision!"
	    diff $TMPDIR/$FILE $WORKDIR/$FILE > $WORKDIR/collisions/$FILE

	  fi

        fi

        # Remove the source file
        unlink $WORKDIR/$FILE

      fi

      # Remove the temp file
      unlink $TMPDIR/$FILE

    done

    # remove temp dir even if it has something left
    rmdir $TMPDIR

  else	# No more hash files found, urllist empty

    # Exit the loop
    break;

  fi

done

#logger -t curl "Deleting $LOCKFILE"

# remove lock file
unlink $LOCKFILE

