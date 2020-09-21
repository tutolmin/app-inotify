#!/bin/bash
#
# The script takes an application server index as a parameter
# Then it creates a lock file for a given app server
# Extracts files into web directory for cache population
# It also checks if there are already >THRESHOLD files in it
#
. /root/.cc_profile

# App server index
APPIDX=$1

# There should be 1 parameter
if [[ "$#" -ne 1 ]]; then
  logger -t extractor "Invalid number of parameters"
  exit
fi

# A mandatory parameter should be a positive integer <APPMAX
if [[ ! "$APPIDX" =~ ^[0-9]+$ || "$APPIDX" -ge $APPMAX ]]; then
  logger -t extractor "Invalid first parameter: '$APPIDX'"
  exit
fi

# Lockfile name selection
LOCKFILE="$ELOCK$APPIDX"

# Create lockfile if not exists, otherwise exit
if [[ ! -e $LOCKFILE ]]; then
#  logger -t extractor "Creating $LOCKFILE < $$"
  logger -t extractor "Creating $LOCKFILE"
  echo $$ > $LOCKFILE
else
  logger -t extractor "$LOCKFILE present!"
  exit
fi

# Extract hash files to the web dir
WORKDIR="$WEBHOME/$APPIDX/hash"

# Proceed only if the work directory has <LOWTHRESHOLD files (ignore collisions dir)
FILES=`ls -A1 $WORKDIR -I collisions | wc -l`
if [[ "$FILES" -lt $LOWTHRESHOLD ]]; then

  # Find the first file in PGN queue dir
  FILE=`find $QUEUEDIR/$APPIDX -type f -print0 -quit`

  # Check if filename is not empty
  if [[ ! -z $FILE ]]; then

    logger -t extractor "Extracting hashes from $FILE"

    # Change directory
    cd $WORKDIR

    # Extract games in to workdir
#    zcat $FILE | $BINDIR/extractor -A $APPDIR/args -l $APPDIR/log$APPIDX -o $APPDIR/err$APPIDX
    zcat $FILE | $BINDIR/extractor -A $APPDIR/args.hashes -l $APPDIR/log.hashes.$APPIDX | $BINDIR/splitter 

    # Move the extracted to backup dir
    mv $FILE $BACKUPDIR/$APPIDX

  fi

else
  logger -t extractor "$WORKDIR has $FILES files (>$LOWTHRESHOLD), skipping!"
fi

logger -t extractor "Deleting $LOCKFILE"

# remove lock file
unlink $LOCKFILE
