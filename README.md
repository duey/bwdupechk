This is my first public open source project.  I've been a user of OSS (Open Source Software) for many years now, but haven't really contributed much.  I just thought I'd release this as I couldn't find it elsewhere.  This is a really basic/simplistic script for this task (like, it doesn't do error checking/failure catching, any syncing (see note at the end) or stuff like that).

**Standard disclaimer**: this software is provided without any warranty and I am not liable for any damages.  I would recommend that you make a backup of your password vault (via Bitwarden's export tools) before using _bwdupechk_.
<br />
<br />
# _bwdupechk_ - Bitwarden Duplicate Checker

A script to check for password duplicates in your Bitwarden password vault.  Written as a Bash script, using the Bitwarden CLI and some OSS tools.
<br />
<br />
<br />
**Software Requirements**:<br />
(I'm unsure what minimum versions would be required, I have provided what I'm using for reference)
<br />
- _bash_
  - Linux shell, and script interpreter
  - I'm using version 5.0.17(1)-release (that comes with Ubuntu 20.04)
- _bw_
  - Bitwarden CLI (Command-line interface)
  - I'm using version 1.12.1, from the Ubuntu Snap store, but this is also available on Bitwarden's website
- _jq_
  - a lightweight and flexible command-line JSON processor
  - I'm using version jq-1.6, from Ubuntu apt repository
- _pr_ 
  - GNU tool to "paginate or columnate files for printing"
  - I'm using version pr (GNU coreutils) 8.30
- _tput_
  - to query terminfo database (for column width)
  - I'm using version ncurses 6.2.20200212
- _diff_
  - GNU tool to compare files line by line
  - I'm using version diff (GNU diffutils) 3.7
  
<br />
<br />

My script requires that you have have already logged into your Bitwarden account via the _bw_ CLI, and that it is unlocked.  It assumes that the _BW_SESSION_ environment variable is set (either in the shell where the script is executed, or in the source of the script).  Basically, if you can run _"bw status --pretty"_ and it shows _"status": "unlocked"_, you're good to go.
<br />
<br />
_bwdupechk_ uses _bw_ to iterate through the entries of your Bitwarden password vault.  It doesn't save a copy, just plugs the entries directly into a _for_ loop.  _jq_ is used to process the JSON output of _bw_ to sort (by password), trim the output and provide the unique vault ID's for the _for_ loop.  It will compare the passwords of the current and previous entries, and if they are the same, present you with the details of the items from _bw_.  _pr_ is used to present the information side by side.  _diff_ is used to show you only what is different between the two items (again, side by side).
<br />

At this point, it will prompt you with a choice of deleting one of them, or not deleting anything and continuing on.  The delete command I use does NOT use the _"--permanent"_ option, so it should just move the item to the Bitwarden Trash folder in your vault.  I do not know if there is a Bitwarden setting that will make _"bw delete"_ by itself irrevocable, so, that's why I suggest that you backup your vault before using this script.
<br />
<br />
**NOTE**: I believe you have to manually sync when using the Bitward CLI software.  What I mean is that, after _bw_ logs in, it'll have a local copy of your vault, and any changes made would be to that local copy.  To actually get it to transfer your changes to the Bitwarden online vault, just run _"bw sync"_.
