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
ROOMS=('sgmr1.pl' 'sgmr2.pl' 'sgmr3.pl' 'sgmr4.pl' 'sgmr5.pl' 'sgmr6.pl' 'sgmr7.pl' 'sgmr8.pl' 'sgmr9.pl')
ROOM_BOOKING=('sgmr1.request.pl' 'sgmr2.request.pl' 'sgmr3.request.pl' 'sgmr4.request.pl' 'sgmr5.request.pl' 'sgmr6.request.pl' 'sgmr7.request.pl' 'sgmr8.request.pl' 'sgmr9.request.pl')
ROOM_CANCEL=('sgmr1.cancel.pl' 'sgmr2.cancel.pl' 'sgmr3.cancel.pl' 'sgmr4.cancel.pl' 'sgmr5.cancel.pl' 'sgmr6.cancel.pl' 'sgmr7.cancel.pl' 'sgmr8.cancel.pl' 'sgmr9.cancel.pl')

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
    raw_data="$(fetch_page_data $BASE_URL${ROOM_BOOKING[0]} '' 1)"
    details=($(echo $raw_data | grep "-$grep_flag" -o "$NAME_REGEX"))
    firstname=${details[0]}
    surname=${details[1]}
    status=${details[2]}
    #strip away [ ] brackets from year (i.e. [ba3] -> ba3)
    year="$(echo $status | sed 's/.*\[//;s/\].*//;')"
}
#set the correct grep flag to be used in order to alow for perl-like regexps syntax
#the flag differs between macOS and Linux
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
# $2 = Start date ->  in the form d Mmm yyyy (11 Sep 2016)
# $3 = End date "" "" "" "" "" ... (if end date is not supplied it will find all of the bookings from the start dates)
function get_bookings {
    bookings="$(echo "$1" | grep "-$grep_flag"o "$2(.*)$3" | grep "-$grep_flag"o "$BOOKING_REGEX")"
    echo "$bookings"
}
#return -> string of \n seperated dates in the format of d Mmm yyyy (11 Sep 2001)
#$1 a string of data containing dates of the d Mmm yyyy format
#$2 date to begin search from
function get_dates {
    if [[ ! -z $1 ]]; then
        upcoming="$(echo "$1" | grep "-$grep_flag"o "$2.*")"
        # printf "%s\n"$upcoming
        dates=""
        #if the date we began search from does not have any bookings the above matching will return blank
        #so we find the previous date that we know for a fact has a booking and try again
        if [ -z "$upcoming" ]; then
            IFS=$'\n' #set the delimiter for converting string to array to be '\n' character
            all_dates=($(echo "$1" | grep "-$grep_flag"o "$BOOKING_DATE_REGEX"))
            unset IFS #scrubidy scrub scrub
            dates="$(get_dates "$1" "${all_dates[@]:(-1)}")"
            echo "$dates"
        else
            dates="$(echo "$upcoming" | grep "-$grep_flag"o "$BOOKING_DATE_REGEX")"
            echo "$dates"
        fi
    fi
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
        raw_data="$(fetch_page_data $BASE_URL${ROOMS[$i-1]} '' 1)"
        dates=($(get_dates "$raw_data" "$DATE"))
        #if there are upcoming bookings, otherwise skip
        if [[ ! -z $dates ]]; then
            printf ${yel}"Room $i"${end}"\n"
            for ((j=0; j < ${#dates[@]}-1; j++)); do
                #fetch the bookings for dates[j]
                bookings=($(get_bookings  $raw_data ${dates[$j]} ${dates[$j+1]}))
                printf "%s:\n" "${dates[$j]}"
                for book in "${bookings[@]}"; do
                    printf "\t%s\n" "${red}$book${end}"
                done
            done
            #post peeling
            bookings=($(get_bookings  $raw_data ${dates[@]:(-1)}))
            printf "%s:\n" "${dates[@]:(-1)}"
            for book in "${bookings[@]}"; do
                printf "\t%s\n" "${red}$book${end}"
            done
        fi
    done
    unset IFS #cleaning up after myself
}
#send a POST booking request for the requested room
#PARAMS:
#array of arguments [startTime, endTime, day, month] (day and month are optional)
function book {
    # declare -a argss=("${!1}") #create the args array from the passed paramater
    argss=("$@")
    room=${argss[@]:(-1)}
    start=${argss[@]:(-2):1}
    end=${argss[@]:(-3):1}
    day=$DAY
    month=$MONTH
    arg_len="${#argss[@]}"
    if [ $arg_len -eq 5 ]; then
        day=${argss[1]}
        month=${argss[0]}
    elif [ $arg_len -eq 4 ]; then
        day=${argss[0]}
    fi
    dataString="StartTime=$start&EndTime=$end&Fullname=$firstname&Status=$year&StartDate=$day&StartMonth=$month&StartYear=1"
    response="$(fetch_page_data $BASE_URL${ROOM_BOOKING[$room -1]} "--data $dataString")"
    status="$(echo $response | grep -o 'SUCCESS\|FAILED\|Booking Pending')"
    case $status in
        "SUCCESS")
            printf "${grn}Booking successfull\n${end}"
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
    for i in $(seq 1 ${#ROOM_CANCEL[@]} ); do #for each room
        response="$(fetch_page_data $BASE_URL${ROOM_CANCEL[$i -1]} "--request POST")"
        #scrape the data required to cancel the room from the data recieved
        cancelValue="$(echo $response | grep "-$grep_flag" -o "$CANCEL_REGEX")"
        #if the cancel string exists (ie a booking exists for logged in user)
        if [[ ! -z $cancelValue ]]; then
            cancelString="Cancel=$cancelValue"
            { curl --data "$cancelString" --user $user:$password $BASE_URL${ROOM_CANCEL[$i -1]}; }&>/dev/null #supress curl output
            #not concerned with result of the curl request. Just hoping it cancels...
            printf "${yel}Room $i booking canceled\n${end}"
        fi
    done
    printf "${cyn}Done${end}\n"
}

#print usage for script
function usage {
    printf "Usage:
    ${red}<required param>${end} ${yel}[optional param]${end}
    ${grn}./glassrooms list
    ./glassrooms book${end} ${red}<room #(1-9)> <start_time(0-23)> <end_time(0-23)>${end} ${yel}[day(1-31)] [month(1-12)]${end}
    ${grn}./glassrooms cancel\n${end}"
}

function main {
    read_config
    printf "${mag}Time: $HOUR:$MINUTES | Date: $DATE\n${end}"
    arg_len="${#BASH_ARGV[@]}"
    args=( "${BASH_ARGV[@]}" )
    #parse arguments
    case ${args[@]:(-1)} in
        'list')
            list
            ;;
        'cancel')
            cancel
            ;;
        'book')
            #minimum 3 paramaters required for booking maximum 5
            if [[ $arg_len -lt 4 || $arg_len -gt 6 ]]; then
                usage
            else
                unset args[${#args[@]}-1] #remove 'booking' string from array
                book "${args[@]}"
            fi
            ;;
        *)
            usage
    esac
}

#runnn Forest ruuuuun
main