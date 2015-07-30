#!/bin/bash

#######################################
#                                     #
#  https://github.com/pedroguima      #
#                                     #
#######################################


if [ -z $1 -o ! -e $1 ]; then
	echo "Please provide a valid file with a list of tickers"
	exit 1
fi

FILE="$1"
LOWEST_IND_RANK=10
URL="http://research.investors.com/Services/AutoSuggest.asmx/GetQuoteResults"
HEADER="Content-Type: application/json; charset=UTF-8"
WGET="/usr/bin/wget"

counter=0
declare -a leaders
IFS=$'\n'
date=$(date -I)
for ticker in $(cat $FILE); do
	json_response=$($WGET $URL --header="$HEADER" --post-data="{\"q\":\"$ticker\",\"limit\":1}" -O - 2> /dev/null )
	ticker_url="http:"$(echo $json_response | awk -F ":" '{print $NF;}' | sed 's/\"\}\]\}//g')
	name=$(echo $json_response | cut -d":" -f5 | cut -d "," -f1 | sed 's/\"//g')
	output=$($WGET $ticker_url -O - 2>/dev/null)
	leader=$(echo -n "$output" | grep " is ranked 1st in Group" | grep $ticker | sed 's/\n//g')
	industry_rank=$(echo -e "$output" | grep -A3 "Industry Group Rank" | grep -o "[0-9]*" )
	number="^[0-9]+"

	if ! [[ $industry_rank =~ $number ]]; then
		continue
	fi
	if [ "$industry_rank" -gt "$LOWEST_IND_RANK" ]; then
		continue
	fi
	if [ -n "$leader" ]; then 
		echo "INSERT INTO stocks values (\"$ticker\", \"$date\", $industry_rank, \"$ticker_url\" );" | mysql finance
	fi
done	

echo -e $leaders | sort -n
