#CONSTANTS
DELIMITER="|"
DATE=`date +%Y%m%d`
HOUR=$(date +%-H)
DAY=$(date +%-d)
MONTH=$(date +%-m)

#Dirty dirty regex for matching string like 25 Aug 2016 (Thursday):11:00-13:00 Hank Hill 
#Remember to use grep with the -E flag to ensure it actually works
REGEX='\d\d* (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{4} \((Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\):\d{2}:\d{2}-\d{2}:\d{2} [A-Z][a-z]+(\s|,)[A-Z][a-z]{1,19}'

NAME_REGEX="[A-Z]?[a-z ,.'-]+ [A-Z]?[a-z ,.'-]+ \[[a-z]{2}\d\]"
ROOMS=('sgmr1.pl' 'sgmr2.pl' 'sgmr3.pl' 'sgmr4.pl' 'sgmr5.pl' 'sgmr6.pl' 'sgmr7.pl' 'sgmr8.pl')
ROOM_BOOKING=('sgmr1.request.pl' 'sgmr2.request.pl' 'sgmr3.request.pl' 'sgmr4.request.pl' 'sgmr5.request.pl' 'sgmr6.request.pl' 'sgmr7.request.pl' 'sgmr8.request.pl')

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

#fetch the naame, surname and year of the logged in student (used for booking and cancelling requests)
function get_name {
    {
        page="$(curl --user $user:$password $LIST_URL/${ROOM_BOOKING[0]})"
        text="$(awk '{gsub("<[^>]*>", "")}1' <<< $page)"
        fullname=($(echo $text | grep -E -o "$NAME_REGEX"))
    }&>/dev/null #supress curl output
    
    firstname=${fullname[0]}
    surname=${fullname[1]}
    status=${fullname[2]}
    year="$(echo $status | sed 's/.*\[//;s/\].*//;')"
    echo $year
}

# return the string of bookings for the room
# $1 room from the rooms array
function fetch_list {    
    {
    page="$(curl --user $user:$password $LIST_URL/$1)" 
    }&>/dev/null #supress curl output

    text="$(awk '{gsub("<[^>]*>", "")}1' <<< $page)"
    book="$(echo $text |  grep -E -o "$REGEX")"
    echo "$book"
}

function list {
    for i in $(seq 1 ${#ROOMS[@]} ); do
       printf ${yel}"Room $i"${end}"\n"
       booking="$(fetch_list ${ROOMS[$i-1]})"
       printf ${red}'%s\n'${end} "${booking}"
    done
}

function book {
    printf "Room #:"
    read room
    printf "\nStart time:"
    read start
    printf "\nEnd time:"
    read endTime
    
    dataString="StartTime=$start&EndTime=$endTime&Fullname=$firstname&Status=$year&StartDate=$DAY&StartMonth=$MONTH&StartYear=1"
    {
        echo "$dataString"
        response="$(curl --data "$dataString" --user $user:$password $LIST_URL/${ROOM_BOOKING[$room -1]})"
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

function main { 
    printf "Username:"
    read  user
    printf "Password:"
    read -s password
    get_name
    printf ${grn}'\nWelcome: %s %s %s\n'${end} "${firstname} ${surname} ${year}"
    while read c; do
        case $c in
            "exit")
                exit
                ;;
            "ls")
                list
                ;;
            "book")
                book
                ;;
            "cancel")
                echo canceling
                ;;
            *)
                echo 'ls | book | cancel | exit' 
                ;;
            esac
    done
}

main

