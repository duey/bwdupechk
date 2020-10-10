This is my first public open source project.  I've been a user of OSS (Open Source Software) for many years now, but haven't really contributed much.  I just thought I'd release this as I couldn't find it elsewhere.  This is a really basic/simplistic script for this task.

Standard disclaimer: this software is provided without any warranty and I am not liable for any damages.  I would recommend that you make a backup of your password vault (via Bitwarden's export tools) before using bwdupechk.

# bwdupechk - Bitwarden Duplicate Checker

A script to check for password duplicates in your Bitwarden password vault.  Written as a Bash script, using the Bitwarden CLI and some OSS tools.

# Software Requirements:
(I'm unsure what minimum versions would be required, I have provided what I'm using for reference)

> bash 
  - Linux shell, and script interpreter
  - I'm using version 5.0.17(1)-release (that comes with Ubuntu 20.04)
> bw
  - Bitwarden CLI (Command-line interface)
  - I'm using version 1.12.1, from the Ubuntu Snap store, but this is also available on Bitwarden's website
> jq 
  - a lightweight and flexible command-line JSON processor
  - I'm using version jq-1.6, from Ubuntu apt repository 
> pr 
  - GNU tool to "paginate or columnate files for printing"
  - I'm using version pr (GNU coreutils) 8.30
> tput
  - to query terminfo database (for column width)
  - I'm using version ncurses 6.2.20200212
> diff
  - GNU tool to compare files line by line
  - I'm using version diff (GNU diffutils) 3.7
    
My script requires that you have have already logged into your Bitwarden account via the bw CLI, and that it is unlocked.  It assumes that the BW_SESSION environment variable is set (either in the shell where the script is executed, or in the source of the script).  Basically, if you can run "bw status --pretty" and it shows "status": "unlocked", you're good to go.

bwdupechk uses bw to iterate through the entries of your Bitwarden password vault.  It doesn't save a copy, just plugs the entries directly into a for loop.  jq is used to process the JSON output of bw to sort (by password), trim the output and provide the unique vault ID's for the for loop.  It will compare the passwords of the current and previous entries, and if they are the same, present you with the details of the items from bw.  pr is used to present the information side by side.  diff is used to show you only what is different between the two items (again, side by side).

At this point, it will prompt you with a choice of deleting one of them, or not deleting anything and continuing on.  The delete command I use does NOT use the "--permanent" option, so it should just move the item to the Bitwarden Trash folder in your vault.  I do not know if there is a Bitwarden setting that will make "bw delete" by itself irrevocable.
