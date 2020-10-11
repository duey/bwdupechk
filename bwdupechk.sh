#!/bin/bash

# if you have a Bitwarden session key, you can add it here
# (will have to be updated whenever you unlock Bitwarden CLI)
#export BW_SESSION=""

echo "Welcome to bwdupechk!"

echo
echo "Checking bw's status ..."

# check if bw command is not working
# 2>&1 to redirect stderr to stdout, to get all output in one
# with --quiet, nothing will output if things are OK
if [ "`bw status --quiet 2>&1`" != "" ]; then
  echo "> bw status command failed, error is as follows:"
  bw status --quiet
  exit
fi

# the "bw status" has the ... well, status (locked or unlocked)
# as well as the last synced time, which is important as bw
# needs to be synced manually

bwstatusoutput="$(bw status 2>/dev/null)"

bwstatus=$(echo $bwstatusoutput | jq -r '.status')

if [ "$bwstatus" != "unlocked" ]; then
  echo "> bw status is not unlocked, cannot continue"
  echo "Current bw status reported:" $bwstatus

  echo -n "Please enter \"bw "
  case "$bwstatus" in
    "locked") echo -n "unlock\" " ;;
    *) echo -n "login\" or \"bw unlock\" (as required) " ;;
  esac

  echo "and follow bw's instructions, then re-run bwduepchk"
  exit
fi

echo "> status:" $bwstatus

lastsync=$(echo $bwstatusoutput | jq -r '.lastSync')

echo "Last sync:" `date -d "$lastsync"`
echo "(if this is significantly in the past, please quit and run \"bw sync\")"

read -p "Press Enter to continue (or press Ctrl-C to exit)"

# the commands are a bit slow to show anything, so, just making some output to let the
# user know something is happening
echo
echo "Searching for duplicate passwords ..."

# initialize variables to compare previous password and ID
prevPass=""
prevID=""

# setup for loop to iterate through unique ID's in the list
# the jq line I got from searching online, most of it should be mostly self-explanatory
#   - the "-r" provides "raw" output (ie. without quotes around the ID's)
#   - the pipes/lines ( | ) is for jq itself to migrate the data through it's filters
#   - I'm not sure what the middle .[] does, but, it makes it work somehow

for itemID in \
$(bw list items | jq -r 'sort_by( .login.password) | .[] | select( .login.password != null) | .id')
do

  # this is also just to show the user that something is happening
  echo "Item ID#" $itemID

  passwd=$(bw get password $itemID)

  if [ "$passwd" == "$prevPass" ]; then

    # quite dramatic!
    echo
    echo "***** Found password match! ..."
    echo

    # the following prints out the Bitwarden item details side by side, using pr
    # $(tput cols) gets the current width of the terminal/screen and helps pr scale nicely
    # "-m" to merge the input to show items side-by-side
    # "-t" to omit pr's header

    pr -mt -W $(tput cols) \
    <(echo "Left side entry (1)" && bw get item $prevID --pretty) \
    <(echo "Right side entry (2)" && bw get item $itemID --pretty)

    echo
    echo "Differences:"
    echo

    diff --width=$(tput cols) --suppress-common-lines --side-by-side \
    <(echo "Left side entry (1)" && bw get item $prevID --pretty) \
    <(echo "Right side entry (2)" && bw get item $itemID --pretty)


    echo
    read -p "Enter 1 or 2 to delete, enter nothing to skip, or press Ctrl-C to exit ... " input

    case "$input" in
      1)
        echo "Deleting ID#" $prevID
        bw delete item $prevID
        passwd=""
        ;;
      2)
        echo "Deleting ID#" $itemID
        bw delete item $itemID
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
