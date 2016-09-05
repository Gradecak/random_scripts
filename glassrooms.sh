#CONSTANTS  
MONTHS=(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
YEAR=$(date +%-Y)
HOUR=$(date +%-H)
MINUTES=$(date +%-M)
DAY=$(date +%-d)
MONTH=$(date +%-m)
DATE="$DAY ${MONTHS[$MONTH-1]} $YEAR"
CONFIG="$HOME/.glassrooms/config.cfg"
#Dirty dirty regex for matching string like 25 Aug 2016 (Thursday):11:00-13:00 Hank Hill 
#Remember to use grep with the -E flag to ensure it actually works
REGEX='\d\d* (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{4} \((Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\):\d{2}:\d{2}-\d{2}:\d{2} ([A-Z][a-z]+(\s))+'
NAME_REGEX="[A-Z]?[a-z ,.'-]+ [A-Z]?[a-z ,.'-]+ \[[a-z]{2}\d\]"
CANCEL_REGEX="\d{8}\|(([01]?[0-9]|2[0-3]):[0-5][0-9])-(([01]?[0-9]|2[0-3]):[0-5][0-9])[a-z,\|]+[A-Z]?[a-z ,.'-]+[A-Z]?[a-z ,.'-]+\|[a-z]{2}\d\|"

#END POINTS
ROOMS=('sgmr1.pl' 'sgmr2.pl' 'sgmr3.pl' 'sgmr4.pl' 'sgmr5.pl' 'sgmr6.pl' 'sgmr7.pl' 'sgmr8.pl')
ROOM_BOOKING=('sgmr1.request.pl' 'sgmr2.request.pl' 'sgmr3.request.pl' 'sgmr4.request.pl' 'sgmr5.request.pl' 'sgmr6.request.pl' 'sgmr7.request.pl' 'sgmr8.request.pl')
ROOM_CANCEL=('sgmr1.cancel.pl' 'sgmr2.cancel.pl' 'sgmr3.cancel.pl' 'sgmr4.cancel.pl' 'sgmr5.cancel.pl' 'sgmr6.cancel.pl' 'sgmr7.cancel.pl' 'sgmr8.cancel.pl')

#list rooms URL
LIST_URL='https://www.scss.tcd.ie/cgi-bin/webcal/sgmr/'

#printf colours
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

#RUNTIME VARIABLES
user=""
password=""
firstname=""
surname=""
year=""

function read_config {
    #check if the config exists if not create one
    if [ ! -f $CONFIG ]; then
        init
    else
        source $CONFIG
    fi
}

function init {
    printf ${red}"config not found... Initialising config at $CONFIG \n"${end}
    mkdir ~/.glassrooms
    touch "$CONFIG"
    printf "SCSS Username:"
    read user
    printf "SCSS Password:"
    read -s password
    get_name
    echo "user=$user" >> $CONFIG
    echo "password=$password" >> $CONFIG
    echo "firstname=$firstname" >> $CONFIG
    echo "surname=$surname" >> $CONFIG
    echo "year=$year" >> $CONFIG
    #set config file permissions so its only accessible by the user who created it (and root)
    chmod 700 $CONFIG
}

#fetch the naame, surname and year of the logged in student (used for booking and cancelling requests)
function get_name {
    {
        page="$(curl --user "$user:$password" $LIST_URL/${ROOM_BOOKING[0]})"
    }&>/dev/null #supress curl output

    text="$(awk '{gsub("<[^>]*>", "")}1' <<< $page)"
    details=($(echo $text | grep -E -o "$NAME_REGEX"))
    firstname=${details[0]}
    surname=${details[1]}
    status=${details[2]}
    year="$(echo $status | sed 's/.*\[//;s/\].*//;')"
    echo $year
}

# return the string of bookings for the room
# $1 = room from the rooms array
function fetch_list {    
    {
    page="$(curl --user "$user:$password" $LIST_URL/$1)" 
    }&>/dev/null #supress curl output

    text="$(awk '{gsub("<[^>]*>", "")}1' <<< $page)"
    book="$(echo $text |  grep -E -o "$REGEX" | grep "$DATE")"
    echo "$book"
}

#list the upcoming bookings for all of the glassrooms
function list {
    for i in $(seq 1 ${#ROOMS[@]} ); do
       printf ${yel}"Room $i"${end}"\n"
       booking="$(fetch_list ${ROOMS[$i-1]})"
       printf ${red}'%s\n'${end} "${booking}"
    done
}

function book { 
    dataString="StartTime=$2&EndTime=$3&Fullname=$firstname&Status=$year&StartDate=$DAY&StartMonth=$MONTH&StartYear=1"
    {
        response="$(curl --data "$dataString" --user "$user:$password" $LIST_URL/${ROOM_BOOKING[$1 -1]})"
    }&>/dev/null #supress curl output
    
    status="$(echo $response | grep -o 'SUCCESS\|FAILED\|Booking Pending')"
    case $status in
        "SUCCESS")
            printf ${grn}"Booking successfull\n"${end}
            ;;
        "FAILED")
            printf ${red}"Booking failed\n"${end}
            ;;
        "Booking Pending")
            printf ${yel}'Too many active bookings\n'${end}
            ;;
        *)
            printf "Uhhh should not be here?\n"
            ;;
    esac
}

function cancel {
    printf ${cyn}"Finding active bookings...\n"${end}
    for i in $(seq 1 ${#ROOM_CANCEL[@]} ); do
    {
        response="$(curl --request POST --user "$user:$password" $LIST_URL/${ROOM_CANCEL[$i-1]})"
    }&>/dev/null #supress curl output
    data="$(echo $response | grep -E -o "$CANCEL_REGEX")"
    
    if [[ ! -z $data ]]; then
        dataString="Cancel=$data"
        {
            res="$(curl --data "$dataString" --user "$user:$password" $LIST_URL/${ROOM_CANCEL[$i-1]})"
        }&>/dev/null #supress curl output
        printf ${yel}"Room $i booking canceled\n"${end}
    fi
    done
    printf ${cyn}"Done\n"${end}
}

#print usage for script
function usage {
    printf ${grn}"Usage:\n ./glassrooms list\n ./glassrooms book <room #(1-8)> <start_time(0-23)> <end_time(0-23>\n ./glassrooms cancel\n\n"${end}
}

function main { 
    read_config 
    printf ${mag}"Current time: $HOUR:$MINUTES\nCurrent Date: $DATE\n"${end}
    arg_len="${#BASH_ARGV[@]}"
    if [ $arg_len -lt 1 ]; then
        help
        exit
    elif [ $arg_len -eq 1 ]; then
        if [ "${BASH_ARGV[0]}" = "list" ]; then
            list
        elif [ "${BASH_ARGV[0]}" = 'cancel' ]; then
            cancel
        else
            usage
        fi
    elif [ $arg_len -eq 4 ]; then
        book "${BASH_ARGV[2]}" "${BASH_ARGV[1]}" "${BASH_ARGV[0]}"
    fi    
}

#runnn Forest ruuuuun
main
