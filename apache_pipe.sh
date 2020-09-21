#!/bin/bash
#
# This simple script is piped by apache and reads data in the following format
# HTTP_code file_name
# 200 783217a919c0afd73467408404f709e0.json
# If the code equals 200 the file in corresponding web directory is deleted
#

while read code file
do
  if [[ "$code" = "200" && -e $file ]]
  then

#    echo "Deleting $file"

    # Log the event into system log
#    logger -t apache_pipe "Deleting $file"
 
    unlink $file
  fi
done

