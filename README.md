# Scripts:
* [glassrooms](#glassrooms)
* [defolder](#defolder)


## Glassrooms
### What is it?
The Glassrooms script is an alternative to using the dirty dirty scss glassrooms webpage.
It allows you to view, make and cancel bookings all from you shell!

### Usage
To use the script, simply place the script in your home directory (or anywhere else really)
run

`chmod +x <path_to_script>`

And you're good to go!

The first time you run the script you will be prompted for your scss username and password. this information will be stored at `~/.glassrooms/config.cfg` but will only be accessible by the user that ran the script and root.

<span style="background-color:red;">___Therefore take care when running the script on servers where you dont know who has root access___</span>

### Recommended setup
i recommend adding some aliases to your bash_profile or bashrc as follows:

```bash
alias list='<path_to_script>/glassrooms.sh list'
alias book='<path_to_script>/glassrooms.sh book'
alias cancel='<path_to_script>/glassrooms.sh cancel'
```

### Bugs
Definitely doesnt work on Arch, other than that  ¯\\_(ツ)_/¯

## Defolder
### What is it?
You ever download a tv show only to find that some animal put every bloody episode is in its own folder?

Well this script takes care of that by crawling through sub directories and copying them to a destination directory
