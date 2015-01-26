#!/bin/bash
# Get info from investors.com

FILES="NASDAQ.txt"
URL="http://research.investors.com/Services/AutoSuggest.asmx/GetQuoteResults"
HEADER="Content-Type: application/json; charset=UTF-8"
WGET="/usr/bin/wget"
#$WGET "http://www.nasdaq.com/screening/companies-by-industry.aspx?exchange=NASDAQ&render=download" -O NASDAQ.txt 

for file in $FILES; do
	IFS=$'\n'
	for line in `cat $file | cut -d "," -f1 | sed 's/"//g' |  grep -v "-"`; do
		ticker=$(echo -n $line)
		json_response=$($WGET $URL --header="$HEADER" --post-data="{\"q\":\"$ticker\",\"limit\":1}" -O - 2> /dev/null )
		ticker_url="http:"$(echo $json_response | awk -F ":" '{print $NF;}' | sed 's/\"\}\]\}//g')
		name=$(echo $json_response | cut -d":" -f5 | cut -d "," -f1 | sed 's/\"//g')
		#echo "$ticker: $ticker_url"
		output=$($WGET $ticker_url -O - 2>/dev/null)
		leader=$(echo -n "$output" | grep " is ranked 1st in Group" | grep $ticker | sed 's/\n//g')
		
		if [ -n "$leader" ]; then 
			echo "$ticker is a leader in his group"
		fi
	done	
done


