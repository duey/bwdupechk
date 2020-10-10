#!/bin/bash


# bw list items | jq -c  '[.[] | {id}]'

# bw list items | jq 'sort_by( .login.password)'


#sample="$(bw list items | jq 'sort_by( .login.password)'| jq -c  '[.[] | {id}]')"

#bw list items | jq 'sort_by( .login.password)' | jq -c '.[] | .id'


#bw list items | jq 'sort_by( .login.password) | .[] | .id'


#bw list items | jq 'sort_by( .login.password) | .[] | select( .login.password != null) | .login.password'


# initialize variables to compare previous entries
prevPass=""
prevID=""

# setup for loop to iterate through unique ID's in the list
# I'm not sure what the middle .[] does, but, it makes it work somehow

echo
echo "Searching ..."

for itemID in \
$(bw list items | jq -r 'sort_by( .login.password) | .[] | select( .login.password != null) | .id')
do
  echo "Item ID#" $itemID



  passwd=$(bw get password $itemID)
#  echo $passwd
#  echo

  if [ "$passwd" == "$prevPass" ]; then


    echo
    echo "***** Found password match! ..."

# "$(bw get username $prevID)" == "$(bw get username $itemID)" 


    echo

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
    read -p "Enter 1 or 2 to delete, or enter nothing to skip ... " input

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



#for row in $(echo "${sample}" | jq -r '.[] | @base64'); do
#    _jq() {
#     echo ${row} | base64 --decode | jq -r ${1}
#    }

#   echo $(_jq '.id')
#done

#echo "$sample" | jq '.[] | .id'
