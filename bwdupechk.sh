#!/bin/bash

# if you have a Bitwarden session key, you can add it here
# will have to be updated whenever you unlock Bitwarden CLI
#export BW_SESSION=""

echo
echo -n "FYI, the date stamp of bw's last sync was:" $(date -d `bw sync --last`) "(converted to your time zone)"
echo

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
