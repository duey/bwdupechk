#!/bin/bash

# if you have a Bitwarden session key, you can add it to BW_SESSION variable
# below (and uncomment the line, by taking out the # before "export")
# NOTE: it will have to be updated whenever you unlock the Bitwarden CLI
#export BW_SESSION=""


echo "Welcome to bwdupechk!"


# TODO:  check for required software
# - bw
# - jq

echo
echo -n "Checking bw's status, please wait ..."
# in the above echo command, the -n prevents a new line from being printed
# after the text (ie. the cursor stays on the same line)

# check if bw command is not working
# 2>&1 to redirect stderr to stdout, to get all output in one
# with --quiet, nothing will output if things are OK

bwStatusOutput="$(bw status --quiet 2>&1)"

if [ "$bwStatusOutput" != "" ]; then
  echo -e "\n> bw status command failed, error is as follows:\n$bwStatusOutput"
  # in the above, the -e allows echo to interpret the \n as a new line char
  exit
fi

# the "bw status" has the ... well, status (locked or unlocked, etc.)
# as well as the last synced time, which is important as bw CLI
# needs to be synced manually

bwStatusOutput="$(bw status 2>/dev/null)"

bwStatus=$(echo "$bwStatusOutput" | jq -r '.status')

if [ "$bwStatus" != "unlocked" ]; then
  echo -e "\n> bw status is not unlocked, cannot continue.\n"
  echo "Current bw status reported: $bwStatus"

  echo -n "Please enter \"bw "
  case "$bwStatus" in
    "locked") echo -n "unlock\" " ;;
    "unauthenticated") echo -n "login\" " ;;
    *) echo -n "login\" or \"bw unlock\" (as required) " ;;
  esac

  echo "and follow bw's instructions, then run bwduepchk again"
  exit 1
fi

echo
echo "> status: $bwStatus"

lastsync=$(echo "$bwStatusOutput" | jq -r '.lastSync')

echo
echo "Last sync: $(date -d "$lastsync") (converted to your time zone)"
echo "(if this is significantly in the past, please quit and run \"bw sync\")"

# TODO:  add logic to check the amount of time that has passed and if it
# hasn't been that long ago, skip the following prompt
# - maybe also add an option for the user to initiate a bw sync

echo
read -rp "Press Enter to continue (or press Ctrl-C to exit) >"
# apparently using -r with read stops it from interpretting backslashes

# initialize variables to compare previous password and ID in the following for loop
prevPass=""
prevID=""

# I've changed the BW ID list to a variable (instead of as a command at the top of the
# loop) so I can program a way to skip through the list if specified on the command line

echo
echo -n "Getting list of ID's from bw CLI, please wait ..."

# setup BWitemlist (the list for the loop) to iterate through unique Bitwarden ID's

BWitemlist=$(bw list items | jq -r 'sort_by( .login.password) | .[] | select( .login.password != null) | .id')

# the jq line I got from searching online, most of it should be mostly self-explanatory
#  - the "-r" provides "raw" output (ie. without quotes around the ID's)
#  - the pipes/lines ( | ) is for jq itself to migrate the data through it's filters
#  - I'm not sure what the middle .[] does, but, it makes it work somehow


# continue output on next line (after echo -n above)
echo

if [ "$1" != "" ] ; then
  # santize provided paramater string, by removing anything that's not alphanumeric or a dash
  startID=${1//[^a-zA-Z0-9\-]/}

  # check if parameter provided is actually in the list of ID's
  # using bash regex search (indicated by the ~ after = in the following if statement)
  # using this as it'll allow me to search for spaces around the provided ID (ie. a whole
  # word, and not a part of an ID)
  if [[ $BWitemlist =~ [[:space:]]$startID[[:space:]] ]] ; then
    # now, cut out beginning of list until the provided ID...

    BWitemlist=${BWitemlist#*$startID*}
    # Bash string manipulation, requires the curly brackets { }
    # using the hash symbol ( # ), the string will be cut from the beginning
    # of the variable until the first occurance of the provided substring

    # since the above removes the actual ID provided, add it back in
    # I know that I can combine this and the above command, but, I like easier to
    # understand code
    BWitemlist="$startID $BWitemlist"

    echo
    echo "Starting search at ID: $startID"
  else
    echo
    echo "Provided ID ($startID) not found, starting from top of list."
  fi
fi

# the commands are a bit slow to show anything, so, just making some output to let the
# user know something is happening
echo
echo "Searching for duplicate passwords ..."

for itemID in $BWitemlist ; do
  # this is also just to show the user that something is happening
  echo "Item ID: $itemID"

  passwd=$(bw get password "$itemID")

  if [ "$passwd" == "$prevPass" ]; then

# TODO: probably should add a test to see if the "username" is the same or not
# perhaps the website as well, but, that's a bit more complex
# (could maybe check diff output for "uri"?

    echo
    echo "***** Found password match!"    # quite dramatic!
    echo -n "Getting details of these items, please wait ."

    prevItemLines=$(bw get item "$prevID" --pretty)

    # just because I can, I'll output another dot
    echo -n "."
    currItemLines=$(bw get item "$itemID" --pretty)

    echo "."
    echo

    # $(tput cols) gets the current width of the terminal/screen and helps pr scale nicely

    scrncols=$(tput cols)

    # the following prints out the Bitwarden item details side by side, using pr
    # "-m" to merge the input to show items side-by-side
    # "-t" to omit pr's header

    pr -mt -W "$scrncols" \
    <(echo "Left side entry (1)" && echo "$prevItemLines") \
    <(echo "Right side entry (2)" && echo "$currItemLines")

    echo
    echo "Differences:"
    echo

    diff --width="$scrncols" --suppress-common-lines --side-by-side \
    <(echo "Left side entry (1)" && echo "$prevItemLines") \
    <(echo "Right side entry (2)" && echo "$currItemLines")

    echo
    echo "Enter 1 or 2 to delete (the corresponding entry), enter nothing"
    read -rp "to skip and continue on, or press Ctrl-C to exit script >" input

# TODO: IDEA: maybe add a "merge" option
# - would attempt to merge the two entries into one
# - not sure if I'd have to create a whole new entry?

# TODO: maybe also add a "q to quit" option
# - that way I can ask the user if they want to sync their changes before exiting
# - or, even put a "sync changes" option in the above prompt?

    case "$input" in
      1)
        echo "Deleting ID: $prevID"
        bw delete item "$prevID"
        passwd=""
        ;;
      2)
        echo "Deleting ID: $itemID"
        bw delete item "$itemID"
        passwd=""
        ;;
      *)
        echo ".... leaving things as-is"
        ;;
    esac

    echo
  fi


  prevPass=$passwd
  prevID=$itemID
done
