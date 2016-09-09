#CONSTANTS
MONTHS=(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
YEAR=$(date +%-Y)
HOUR=$(date +%-H)
MINUTES=$(date +%-M)
DAY=$(date +%-d)
MONTH=$(date +%-m)
#Current date in the 'dd Mmm yyyy' format eg 01 Apr 2004
DATE="$DAY ${MONTHS[$MONTH-1]} $YEAR"
CONFIG="$HOME/.glassrooms/config.cfg"

#Dirty dirty regex for matching string like 25 Aug 2016 (Thursday):11:00-13:00 Hank Hill
BOOKING_DATE_REGEX='\d\d* (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{4}'
BOOKING_REGEX='\d{2}:\d{2}-\d{2}:\d{2} ([A-Z][a-z]+(\s))+'
NAME_REGEX="[A-Z]?[a-z ,.'-]+ [A-Z]?[a-z ,.'-]+ \[[a-z]+\d\]"
CANCEL_REGEX="\d{8}\|(([01]?[0-9]|2[0-3]):[0-5][0-9])-(([01]?[0-9]|2[0-3]):[0-5][0-9])[a-z,\|]+[A-Z]?[a-z ,.'-]+[A-Z]?[a-z ,.'-]+\|[a-z]{2}\d\|"
TIME_REGEX="\d{2}:\d{2}-\d{2}:\d{2}"

#END POINTS
ROOMS=('sgmr1.pl' 'sgmr2.pl' 'sgmr3.pl' 'sgmr4.pl' 'sgmr5.pl' 'sgmr6.pl' 'sgmr7.pl' 'sgmr8.pl')
ROOM_BOOKING=('sgmr1.request.pl' 'sgmr2.request.pl' 'sgmr3.request.pl' 'sgmr4.request.pl' 'sgmr5.request.pl' 'sgmr6.request.pl' 'sgmr7.request.pl' 'sgmr8.request.pl')
ROOM_CANCEL=('sgmr1.cancel.pl' 'sgmr2.cancel.pl' 'sgmr3.cancel.pl' 'sgmr4.cancel.pl' 'sgmr5.cancel.pl' 'sgmr6.cancel.pl' 'sgmr7.cancel.pl' 'sgmr8.cancel.pl')

#list rooms URL
BASE_URL='https://www.scss.tcd.ie/cgi-bin/webcal/sgmr/'

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

#initialise the config file for the script (in order to speed up future use)
#function is only run on first use of script
function init {
    printf ${red}"config not found... Initialising config at $CONFIG \n"${end}
    printf ${red}"WARNING: your username and password will be stored in the home folder, anyone in the sudoers file can access it. Proceed with caution!! :WARNING\n"${end}
    mkdir ~/.glassrooms     #create the glassrooms directory
    touch "$CONFIG"         #craete the config file
    printf "SCSS Username:"
    read user
    printf "SCSS Password:\n"
    read -s password
    grep_flag="$(set_grep_flag)"
    get_name
    #write variables to config file
    echo "grep_flag=$grep_flag" >> $CONFIG
    echo "user=$user" >> $CONFIG
    echo "password=$password" >> $CONFIG
    echo "firstname=$firstname" >> $CONFIG
    echo "surname=$surname" >> $CONFIG
    echo "year=$year" >> $CONFIG
    #set config file permissions so its only accessible by the user who created it (and root)
    chmod 700 $CONFIG
}

#fetch the naame, surname and year of the logged in student (used for booking requests)
function get_name {
    raw_data="$(fetch_page_data $BASE_URL/${ROOM_BOOKING[0]} '' 1)"
    details=($(echo $raw_data | grep "-$grep_flag" -o "$NAME_REGEX"))
    firstname=${details[0]}
    surname=${details[1]}
    status=${details[2]}
    #strip away [ ] brackets from year (i.e. [ba3] -> ba3)
    year="$(echo $status | sed 's/.*\[//;s/\].*//;')"
}
#set the correct grep flag to be used in order to alow for perl-like regexps syntax
#the flag differs between Os X and Linux
#Flag = -P for linux
#     = -E for Os X
function set_grep_flag {
    env="$(uname -s)"
    if [[ $env = "Linux" ]]; then
        echo "P"
    elif [[ $env = "Darwin" ]]; then
        echo "E"
    fi
}
# return -> string of bookings for the room for the specified dates (seperated by \n)
# PARAMS:
# $1 = data for the page
# $2 = Start date ->  in the form d Mmm yyyy (9 Sep 2016)
# $3 = End date "" "" "" "" "" ... (if end date is not supplied it will find all of the bookings from the start dates)
function get_bookings {
    bookings="$(echo "$1" | grep "-$grep_flag"o "$2(.*)$3" | grep "-$grep_flag"o "$BOOKING_REGEX")"
    echo "$bookings"
}
#Return a string of \n seperated dates in the format of d Mmm yyyy (1 Sep 2006)
#$1 a string of data containing dates of the d Mmm yyyy format
function get_dates {
    upcoming="$(echo "$1" | grep "-$grep_flag"o "$DATE.*" | grep "-$grep_flag"o "$BOOKING_DATE_REGEX")"
    echo "$upcoming"
}
#return -> stripped data response for requested page
# PARAMS:
#$1 = request URL
#$2 = CURL paramaters
#$3 = Strip HTML tags from returned page
function fetch_page_data {
    { page="$(curl $2 --user "$user:$password" $1)"; }&>/dev/null #supress curl output
    #if the strip html flag is set
    if [[ ! -z $3 ]]; then
        raw_data="$(awk '{gsub("<[^>]*>", "")}1' <<< $page)"  #strip away all html tags
        echo "$raw_data"
    else
        echo "$page"
    fi
}
#list the upcoming bookings for all of the rooms
function list {
    IFS=$'\n' #set the delimiter for converting string to array to be '\n' character
    for i in $(seq 1 ${#ROOMS[@]} ); do
        raw_data="$(fetch_page_data $BASE_URL/${ROOMS[$i-1]} '' 1)"
        dates=($(get_dates $raw_data))
        #if there are upcoming bookings, otherwise skip
        if [[ ! -z $dates ]]; then
            printf ${yel}"Room $i"${end}"\n"
            for ((j=0; j < ${#dates[@]}-1; j++)); do
                #fetch the bookings for dates[j]
                bookings=($(get_bookings  $raw_data ${dates[$j]} ${dates[$j+1]}))
                printf "%s\n%s\n" "${blu}${dates[$j]}${end}" "${red}${bookings[@]}${end}"
            done
            bookings=($(get_bookings  $raw_data ${dates[@]:(-1)}))
            printf "%s\n%s\n" "${blu}${dates[@]:(-1)}${end}" "${red}${bookings[@]}${end}"
        fi
    done
    unset IFS #cleaning up after myself
}

function available {
    # available=""
    # tomorrow="$(($DAY+1)) ${MONTHS[$MONTH-1]} $YEAR"
    # current_hour="$HOUR:00-$(($HOUR+1)):00" #booked for current hour
    # two_hours="$HOUR:00-$(($HOUR+2)):00" #booked for current hour + next hour
    # next_hour="$(($HOUR+1)):00-$(($HOUR+2)):00" #booked for next hour
    # next_two_hours="$(($HOUR+1)):00-$(($HOUR+3)):00" #bookef for next 2 hours

    # printf "${cyn}Fetching Data...${end}\n"
    # IFS=$'\n' #set the delimiter for converting string to array to be '\n' character
    # #for every room
    # for i in $(seq 1 ${#ROOMS[@]} ); do
    #     raw_data="$(fetch_page_data $BASE_URL/${ROOMS[$i-1]} '' 1)"
    #     bookings=($(get_bookings $raw_data $DATE $tomorrow)) #get bookings between today and tomorrow
    #     for i in ${bookings[@]};  do

    #     done
    # done
    # unset IFS #cleanup on isle 4
    printf "\nCurrently available rooms:%s\n""$available"
}


function book {
    dataString="StartTime=$2&EndTime=$3&Fullname=$firstname&Status=$year&StartDate=$DAY&StartMonth=$MONTH&StartYear=1"
    response="$(fetch_page_data $BASE_URL/${ROOM_BOOKING[$1 -1]} "--data $dataString")"
    status="$(echo $response | grep -o 'SUCCESS\|FAILED\|Booking Pending')"
    case $status in
        "SUCCESS")
            printf ${grn}"Booking successfull\n"${end}
            ;;
        "FAILED")
            printf ${red}"Booking failed\n"${end}
            ;;
        "Booking Pending")
            printf ${yel}"Too many active bookings\n"${end}
            ;;
        *)
            printf "Uhhh should not be here?\n"
            ;;
    esac
}

#Finds all the active bookings, scrape the cancelation string and submit it to the server
function cancel {
    printf "${cyn}Finding active bookings...\n${end}"
    for i in $(seq 1 ${#ROOM_CANCEL[@]} ); do
        response="$(fetch_page_data $BASE_URL/${ROOM_CANCEL[$i-1]} "--request POST")"
        cancelValue="$(echo $response | grep "-$grep_flag" -o "$CANCEL_REGEX")"
        #if the cancel string exists (ie a booking exists for logged in user)
        if [[ ! -z $cancelValue ]]; then
            cancelString="Cancel=$cancelValue"
            echo $cancelString
            res="$(fetch_page_data $BASE_URL/${ROOM_CANCEL[$i-1]} "--data $cancelString")"
            echo $res
            printf "${yel}Room $i booking canceled\n${end}"
        fi
    done
    printf "${cyn}Done${end}\n"
}

#print usage for script
function usage {
    printf "${grn}Usage:
     ./glassrooms list
     ./glassrooms book <room #(1-8)> <start_time(0-23)> <end_time(0-23)>
     ./glassrooms cancel
     ./glassrooms available
     ${end}"
}
function main {
    read_config
    printf "${mag}Time: $HOUR:$MINUTES | Date: $DATE\n${end}"
    arg_len="${#BASH_ARGV[@]}"
    if [ $arg_len -lt 1 ]; then
        usage
        exit 1
    elif [ $arg_len -eq 1 ]; then
        if [ "${BASH_ARGV[0]}" = "list" ]; then
            list
        elif [ "${BASH_ARGV[0]}" = 'cancel' ]; then
            cancel
        elif [ "${BASH_ARGV[0]}" = 'available' ]; then
            available
        else
            usage
        fi
    elif [ $arg_len -eq 4 ]; then
        book "${BASH_ARGV[2]}" "${BASH_ARGV[1]}" "${BASH_ARGV[0]}"
    fi
}

#runnn Forest ruuuuun
main